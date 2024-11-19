locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
}

data "azurerm_resource_group" "resgrp" {
  name = join("-", ["cdpz", var.environment, "data-streaming-rg"])
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = join("-", ["cdpz", var.environment, "data-streaming-ehns-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_user_assigned_identity" "umi1" {
  name                = join("-", ["cdpz", var.environment, "ingestion-ila-ehns-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_user_assigned_identity" "umi2" {
  name                = join("-", ["cdpz", var.environment, "ingestion-ila-opsi-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

data "azurerm_subnet" "snet-srvend" {
  count                = length(var.service_endpoint_snets)

  resource_group_name  = var.service_endpoint_snets[count.index].rgname
  virtual_network_name = var.service_endpoint_snets[count.index].vnet
  name                 = var.service_endpoint_snets[count.index].snet
}

data azurerm_subnet cdmz-snet-srvend {
    #If public access is enabled snets will be whitelisted
    count                = length(var.cdmz_service_endpoint_snets)
    provider             = azurerm.cdmz

    resource_group_name  = var.cdmz_service_endpoint_snets[count.index].rgname
    virtual_network_name = var.cdmz_service_endpoint_snets[count.index].vnet
    name                 = var.cdmz_service_endpoint_snets[count.index].snet
}

resource "azurerm_eventhub_namespace" "portsterms" {
  name = join("-", ["cdpz", var.environment, "ingestion-portsterms-evh01"])

  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
  tags                = merge(var.resource_tags_common, var.resource_tags_spec)

  public_network_access_enabled = true
  sku                           = "Standard"
  capacity                      = 3
  zone_redundant                = true
  auto_inflate_enabled          = true
  maximum_throughput_units      = 4

  network_rulesets {
    default_action                 = "Deny"
    ip_rule {
      ip_mask = "34.247.45.255"
      action  = "Allow"
    }
    trusted_service_access_enabled = true
    virtual_network_rule = [
      for s in concat(
         data.azurerm_subnet.snet-srvend, 
         data.azurerm_subnet.cdmz-snet-srvend, 
         ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]) :
      {
        subnet_id = data.azurerm_subnet.snet.id
        ignore_missing_virtual_network_service_endpoint = "true"
      }
    ]
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi.id]
  }
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.servicebus.windows.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "pep" {
  name                            = join("-", ["cdpz", var.environment, "data-streaming-portsterms-pep"])  
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "data-streaming-portsterms-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "data-streaming-portsterms-psc"])
    private_connection_resource_id  = azurerm_eventhub_namespace.portsterms.id
    subresource_names               = ["namespace"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                =   join("-", ["cdpz", var.environment, "data-streaming-portsterms-ipc"])
    private_ip_address  =   var.private_endpoint_ip_address
    subresource_name    =   "namespace"
    member_name         =   "namespace"
  }

  tags    = merge(
    var.resource_tags_spec
  )

  lifecycle {
      ignore_changes  = all
  }

  depends_on = [
    azurerm_eventhub_namespace.portsterms,
    data.azurerm_private_dns_zone.pdnsz,
    data.azurerm_subnet.snet
  ]
}

resource "azurerm_eventhub" "tiot_delayed" {
    name                = "tiot_delayed"
    namespace_name      = azurerm_eventhub_namespace.portsterms.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 2
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 60
      size_limit_in_bytes = 419430400
      skip_empty_archives = true
      destination {
        archive_name_format = "pt_docau/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "iot-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_tiot_delayed
            }
    }
}

resource "azurerm_eventhub" "tiot_error" {
    name                = "tiot_error"
    namespace_name      = azurerm_eventhub_namespace.portsterms.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 2
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 60
      size_limit_in_bytes = 419430400
      skip_empty_archives = true
      destination {
        archive_name_format = "pt_docau/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "iot-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_tiot_error
            }
    }
}

resource "azurerm_eventhub" "tiot_event" {
    name                = "tiot_event"
    namespace_name      = azurerm_eventhub_namespace.portsterms.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 2
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 60
      size_limit_in_bytes = 419430400
      skip_empty_archives = true
      destination {
        archive_name_format = "pt_docau/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "iot-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_tiot_event
            }
    }
}

resource "azurerm_eventhub" "tiot_uptime" {
    name                = "tiot_uptime"
    namespace_name      = azurerm_eventhub_namespace.portsterms.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 2
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 60
      size_limit_in_bytes = 419430400
      skip_empty_archives = true
      destination {
        archive_name_format = "pt_docau/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "iot-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_tiot_uptime
            }
    }
}

## Event Hub Configuration for Mix

resource "azurerm_eventhub_namespace" "ila" {
  name = join("-", ["cdpz", var.environment, "ingestion-ila-mix-evh01"])

  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
  tags                = merge(var.resource_tags_common, var.resource_tags_spec)

  public_network_access_enabled = true
  sku                           = "Standard"
  capacity                      = 1
  zone_redundant                = true
  auto_inflate_enabled          = true
  maximum_throughput_units      = 4

  network_rulesets {
    default_action                 = "Deny"
    ip_rule {
      ip_mask = "34.247.45.255"
      action  = "Allow"
    }
    trusted_service_access_enabled = true
    virtual_network_rule = [
      for s in concat(
         data.azurerm_subnet.snet-srvend, 
         data.azurerm_subnet.cdmz-snet-srvend, 
         ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]) :
      {
        subnet_id = data.azurerm_subnet.snet.id
        ignore_missing_virtual_network_service_endpoint = "true"
      }
    ]
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi1.id]
  }
}

resource "azurerm_private_endpoint" "pep-ila" {
  name                            = join("-", ["cdpz", var.environment, "data-streaming-ila-pep"])  
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "data-streaming-ila-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "data-streaming-ila-psc"])
    private_connection_resource_id  = azurerm_eventhub_namespace.ila.id
    subresource_names               = ["namespace"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                =   join("-", ["cdpz", var.environment, "data-streaming-ila-ipc"])
    private_ip_address  =   var.private_endpoint_ip_address_ilamix
    subresource_name    =   "namespace"
    member_name         =   "namespace"
  }

  tags    = merge(
    var.resource_tags_spec
  )

  lifecycle {
      ignore_changes  = all
  }

  depends_on = [
    azurerm_eventhub_namespace.ila,
    data.azurerm_private_dns_zone.pdnsz,
    data.azurerm_subnet.snet
  ]
}

resource "azurerm_eventhub" "events" {
    name                = "events"
    namespace_name      = azurerm_eventhub_namespace.ila.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    message_retention   = 1
    partition_count     = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "VehicleTelematicsSystems/Mix/Streams/Events/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_events
            }
    }
    lifecycle {
      ignore_changes  = all
  }
}

resource "azurerm_eventhub" "positions" {
    name                = "positions"
    namespace_name      = azurerm_eventhub_namespace.ila.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 1
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "VehicleTelematicsSystems/Mix/Streams/Positions/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_positions
            }
     }
    lifecycle {
      ignore_changes  = all
  }
}

resource "azurerm_eventhub" "trips" {
    name                = "trips"
    namespace_name      = azurerm_eventhub_namespace.ila.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 1
    message_retention   = 1
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "VehicleTelematicsSystems/Mix/Streams/Trips/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_trips
            }
    }
    lifecycle {
      ignore_changes  = all
  }
}

## Event Hub Configuration for ILA OPSI

resource "azurerm_eventhub_namespace" "ila-opsi" {
  name = join("-", ["cdpz", var.environment, "ingestion-ila-opsi-evh01"])

  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
  tags                = merge(var.resource_tags_ila_opsi)

  public_network_access_enabled = true
  sku                           = "Standard"
  capacity                      = 1
  zone_redundant                = true
  auto_inflate_enabled          = true
  maximum_throughput_units      = 4

  network_rulesets {
    default_action                 = "Deny"
    ip_rule {
      ip_mask = "4.221.198.16"
      action  = "Allow"
    }
    trusted_service_access_enabled = true
    virtual_network_rule = [
      for s in concat(
         data.azurerm_subnet.snet-srvend, 
         data.azurerm_subnet.cdmz-snet-srvend, 
         ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]) :
      {
        subnet_id = data.azurerm_subnet.snet.id
        ignore_missing_virtual_network_service_endpoint = "true"
      }
    ]
  }
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi2.id]
  }
}

resource "azurerm_private_endpoint" "pep-ila-opsi" {
  name                            = join("-", ["cdpz", var.environment, "data-ingestion-ila-pep"])  
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "data-ingestion-ila-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "data-ingestion-ila-psc"])
    private_connection_resource_id  = azurerm_eventhub_namespace.ila-opsi.id
    subresource_names               = ["namespace"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                =   join("-", ["cdpz", var.environment, "data-ingestion-ila-ipc"])
    private_ip_address  =   var.private_endpoint_ip_address_ila_opsi
    subresource_name    =   "namespace"
    member_name         =   "namespace"
  }

  tags    = merge(
    var.resource_tags_ila_opsi
  )

  lifecycle {
      ignore_changes  = [
          subnet_id
      ]
  }

  depends_on = [
    azurerm_eventhub_namespace.ila,
    data.azurerm_private_dns_zone.pdnsz,
    data.azurerm_subnet.snet
  ]
}

resource "azurerm_eventhub" "workflow_events" {
    name                = "workflow_events"
    namespace_name      = azurerm_eventhub_namespace.ila-opsi.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 1
    message_retention   = 1
    depends_on = [ azurerm_eventhub_namespace.ila-opsi ]
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "ila_opsi/mobility/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_workflow_events
            }
    }
}

resource "azurerm_eventhub" "workflow_states" {
    name                = "workflow_states"
    namespace_name      = azurerm_eventhub_namespace.ila-opsi.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 1
    message_retention   = 1
    depends_on = [ azurerm_eventhub_namespace.ila-opsi ]
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "ila_opsi/mobility/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_workflow_states
            }
    }
}

resource "azurerm_eventhub" "test" {
    name                = "test"
    namespace_name      = azurerm_eventhub_namespace.ila-opsi.name
    resource_group_name = data.azurerm_resource_group.resgrp.name
    partition_count     = 1
    message_retention   = 1
    depends_on = [ azurerm_eventhub_namespace.ila-opsi ]
    capture_description {
      enabled             = true
      encoding            = "Avro"
      interval_in_seconds = 300
      size_limit_in_bytes = 314572800
      skip_empty_archives = true
      destination {
        archive_name_format = "ila_opsi/mobility/{EventHub}/{Year}/{Month}/{Day}/{Namespace}-{EventHub}-{PartitionId}{Hour}{Minute}{Second}"
        blob_container_name = "ila-data01"
        name                = "EventHubArchive.AzureBlockBlob"
        storage_account_id  = var.strg_opsi_test
            }
    }
}
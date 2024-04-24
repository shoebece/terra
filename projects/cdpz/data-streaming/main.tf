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

resource "azurerm_eventhub_namespace" "ehns" {
  name = join("-", ["cdpz", var.environment, "data-streaming-ehns"])

  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
  tags                = merge(var.resource_tags_common, var.resource_tags_spec)

  public_network_access_enabled = true
  sku                           = "Standard"
  capacity                      = 1
  zone_redundant                = true

  network_rulesets {
    default_action                 = "Deny"
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
  name                            = join("-", ["cdpz", var.environment, "data-streaming-ehns-pep"])  
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "data-streaming-ehns-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "data-streaming-ehns-psc"])
    private_connection_resource_id  = azurerm_eventhub_namespace.ehns.id
    subresource_names               = ["namespace"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                =   join("-", ["cdpz", var.environment, "data-streaming-ehns-ipc"])
    private_ip_address  =   var.private_endpoint_ip_address
    subresource_name    =   "namespace"
    member_name         =   "namespace"
  }

  tags    = merge(
    var.resource_tags_spec
  )

  lifecycle {
      ignore_changes  = [
          subnet_id
      ]
  }

  depends_on = [
    azurerm_eventhub_namespace.ehns,
    data.azurerm_private_dns_zone.pdnsz,
    data.azurerm_subnet.snet
  ]
}

resource "azurerm_eventhub" "ehs" {
    name                = "data-streaming"
    namespace_name      = azurerm_eventhub_namespace.ehns.name
    resource_group_name = data.azurerm_resource_group.resgrp.name

    partition_count     = 2
    message_retention   = 1

    depends_on = [ azurerm_eventhub_namespace.ehns ]
}
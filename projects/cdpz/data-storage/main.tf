locals {
  devops_subnet_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"
}

# To be deleted after migration to new infra
locals {
  old_prod_dbx_subnet_id = ["/subscriptions/3c44ba2d-eba5-4d51-adb8-8614bf03bd29/resourceGroups/Rg-BADatabricks-Prod/providers/Microsoft.Network/virtualNetworks/vnet-badatabricks-prod/subnets/DBR_Private",
    "/subscriptions/3c44ba2d-eba5-4d51-adb8-8614bf03bd29/resourceGroups/Rg-BADatabricks-Prod/providers/Microsoft.Network/virtualNetworks/vnet-badatabricks-prod/subnets/DBR_Public",
    "/subscriptions/3c44ba2d-eba5-4d51-adb8-8614bf03bd29/resourceGroups/Rg-BADatabricks-Prod/providers/Microsoft.Network/virtualNetworks/vnet-badatabricks-prod/subnets/snet_privatelink"]
}

data "azurerm_resource_group" "resgrp" {
  name      = join("-", ["cdpz", var.environment, "data-storage-rg"])
}

resource "azurerm_management_lock" "delete-lock" {
  name       = "resource-group-deletion-lock"
  scope      = data.azurerm_resource_group.resgrp.id
  lock_level = "CanNotDelete"
}

data "azurerm_key_vault" "kv" {
  name                  = var.sandbox_prefix == "" ? join("-", ["cdpz", var.environment, "data-kv"]) : join("-", ["cdpz", var.environment, var.sandbox_prefix, "data-kv"])
  resource_group_name   = data.azurerm_resource_group.resgrp.name
}

data "azurerm_key_vault_key" "cmk" {
  name         = join("-", ["cdpz", var.environment, "data-storage-dls-cmk"])
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = join("-", ["cdpz", var.environment, "data-storage-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_role_assignment" "umi_to_kv" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.umi.principal_id
}

# Whitelisted networks - to be uncommented if public endpoint will be enable
# --------------------------------------------------------------------------
data azurerm_subnet snet-srvend {
    # If public access is enabled snets will be whitelisted
    count                = length(var.service_endpoint_snets) * (var.public_access_enabled ? 1 : 0)

    resource_group_name  = var.service_endpoint_snets[count.index].rgname
    virtual_network_name = var.service_endpoint_snets[count.index].vnet
    name                 = var.service_endpoint_snets[count.index].snet
}

data azurerm_subnet cdmz-snet-srvend {
    # If public access is enabled snets will be whitelisted
    count                = length(var.cdmz_service_endpoint_snets) * (var.public_access_enabled ? 1 : 0)
    provider             = azurerm.cdmz

    resource_group_name  = var.cdmz_service_endpoint_snets[count.index].rgname
    virtual_network_name = var.cdmz_service_endpoint_snets[count.index].vnet
    name                 = var.cdmz_service_endpoint_snets[count.index].snet
}

data azurerm_subnet additional-snet-srvend {
    # If public access is enabled snets will be whitelisted
    count                = length(var.additional_service_endpoint_snets) * (var.public_access_enabled ? 1 : 0)
    provider             = azurerm.dev

    resource_group_name  = var.additional_service_endpoint_snets[count.index].rgname
    virtual_network_name = var.additional_service_endpoint_snets[count.index].vnet
    name                 = var.additional_service_endpoint_snets[count.index].snet
}

resource "azurerm_storage_account" "data_staccs" {
  count                     = length(var.staccs)
  
  name                      = join("", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls"])
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  location                  = var.resource_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  public_network_access_enabled       = var.public_access_enabled
  allow_nested_items_to_be_public     = false
  min_tls_version           = "TLS1_2"
  is_hns_enabled            = true
  account_kind              = "StorageV2"
  
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.umi.id
    ]
  }

  network_rules {
    default_action              = "Deny"
    virtual_network_subnet_ids  = concat([for s in concat(data.azurerm_subnet.snet-srvend, data.azurerm_subnet.cdmz-snet-srvend, data.azurerm_subnet.additional-snet-srvend) : s.id ], [local.devops_subnet_id], local.old_prod_dbx_subnet_id)
  }
  
  tags = merge(
    var.resource_tags_common, var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }

  depends_on = [
    data.azurerm_resource_group.resgrp
    ,azurerm_user_assigned_identity.umi]
}

resource "azurerm_storage_account_customer_managed_key" "stacc_cmk" {
  count                     = length(var.staccs)

  storage_account_id        = azurerm_storage_account.data_staccs[count.index].id
  key_vault_id              = data.azurerm_key_vault.kv.id
  key_name                  = data.azurerm_key_vault_key.cmk.name
  user_assigned_identity_id = azurerm_user_assigned_identity.umi.id

  depends_on = [
     azurerm_storage_account.data_staccs
    ,azurerm_user_assigned_identity.umi
    ,azurerm_role_assignment.umi_to_kv]
}

# Optional
data "azurerm_subnet" "snet" {
  count                = var.public_access_enabled ? 0 : 1

  resource_group_name  = join("-", ["cdpz", var.environment, "networking-rg"])
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
  name                 = "processing-default-snet"
}

resource "azurerm_private_endpoint" "endpoint_dls" {
    # If public access is enabled, private end points not needed
    count                           = length(var.staccs) * (var.public_access_enabled ? 0 : 1)

    name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "pep"])  
    resource_group_name             = data.azurerm_subnet.snet[0].resource_group_name
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet[0].id

    custom_network_interface_name   = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "nic"])  

    private_service_connection {
        name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "psc"])
        private_connection_resource_id  = azurerm_storage_account.data_staccs[count.index].id
        subresource_names               = [var.staccs[count.index].pep[0].code]
        is_manual_connection            = false
        }

    ip_configuration {
        name                =   join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "ipc"])
        private_ip_address  =   var.staccs[count.index].pep[0].ip
        subresource_name    =   var.staccs[count.index].pep[0].code
        member_name         =   var.staccs[count.index].pep[0].code
    }

    tags    = merge(
      var.resource_tags_spec
    )

    lifecycle {
        ignore_changes  = [
            subnet_id
        ]
    }

    depends_on = [ azurerm_storage_account.data_staccs ]
}

resource "azurerm_private_endpoint" "endpoint_blob" {
    # If public access is enabled, private end points not needed
    count                           = length(var.staccs) * (var.public_access_enabled ? 0 : 1)

    name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "pep"])  
    resource_group_name             = data.azurerm_subnet.snet[0].resource_group_name
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet[0].id

    custom_network_interface_name   = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "nic"])  

    private_service_connection {
        name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "psc"])
        private_connection_resource_id  = azurerm_storage_account.data_staccs[count.index].id
        subresource_names               = [var.staccs[count.index].pep[1].code]
        is_manual_connection            = false
        }

    ip_configuration {
        name                =   join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "ipc"])
        private_ip_address  =   var.staccs[count.index].pep[1].ip
        subresource_name    =   var.staccs[count.index].pep[1].code
        member_name         =   var.staccs[count.index].pep[1].code
    }

    tags    = merge(
      var.resource_tags_spec
    )

    lifecycle {
        ignore_changes  = [
            subnet_id
        ]
    }

    depends_on = [ azurerm_storage_account.data_staccs ]
}
locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
  # stacc_conts = flatten([
  #   for stacc_key, stacc in var.staccs : [
  #       for cont_key, cont in stacc.stconts : {
  #         key     = join("-", [stacc.stacc, cont])
  #         stacc   = stacc.stacc
  #         cont    = cont
  #       }
  #   ]
  # ])
  stacc_peps = flatten([
    for stacc in var.staccs : [
        for pep in stacc.pep : {
          key       = join("-", [stacc.stacc, pep.code, "pep"])
          stacc     = stacc.stacc
          pep_code  = pep.code
          pep_ip    = pep.ip
        }
    ]
  ])
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

resource "azurerm_storage_account" "data_staccs" {
  for_each                  = { for stacc in var.staccs: stacc.stacc => stacc }
  name                      = join("", ["cdpz", var.environment, each.value.stacc, "dls"])
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  location                  = var.resource_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  public_network_access_enabled       = var.public_access_enabled
  allow_nested_items_to_be_public     = false
  min_tls_version           = "TLS1_2"
  is_hns_enabled            = each.value.is_hns_enabled
  account_kind              = "StorageV2"
  
  identity {
    type = "UserAssigned"
    identity_ids = [
      azurerm_user_assigned_identity.umi.id
    ]
  }

  network_rules {
    default_action              = "Deny"
    virtual_network_subnet_ids  = concat(var.common_service_endpoint_snets, each.value.specyfic_service_endpoint_snets)
  }
  
  dynamic "blob_properties" {
    for_each = each.value.enable_soft_delete ? [1] : []
    content {
      container_delete_retention_policy {
        days = each.value.soft_delete_retention_days
      }
    }
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
  for_each                  = { for stacc in var.staccs: stacc.stacc => stacc }
  storage_account_id        = azurerm_storage_account.data_staccs[each.value.stacc].id
  key_vault_id              = data.azurerm_key_vault.kv.id
  key_name                  = data.azurerm_key_vault_key.cmk.name
  user_assigned_identity_id = azurerm_user_assigned_identity.umi.id

  depends_on = [
     azurerm_storage_account.data_staccs
    ,azurerm_user_assigned_identity.umi
    ,azurerm_role_assignment.umi_to_kv]
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_private_dns_zone" "pdnszs" {
  for_each            = toset( [ "dfs", "blob" ] )
  name                = join(".", [ "privatelink", each.key, "core.windows.net" ])
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint" {
    for_each                        = { for pep in local.stacc_peps: pep.key => pep }
    name                            = join("-", ["cdpz", var.environment, each.value.stacc, "dls", each.value.pep_code, "pep"])  
    resource_group_name             = local.networking_resource_group_name
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet.id

    custom_network_interface_name   = join("-", ["cdpz", var.environment, each.value.stacc, "dls", each.value.pep_code, "nic"])  

    private_dns_zone_group {
      name = "add_to_azure_private_dns"
      private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnszs[each.value.pep_code].id ]
    }

    private_service_connection {
        name                            = join("-", ["cdpz", var.environment, each.value.stacc, "dls", each.value.pep_code, "psc"])
        private_connection_resource_id  = azurerm_storage_account.data_staccs[each.value.stacc].id
        subresource_names               = [each.value.pep_code]
        is_manual_connection            = false
        }

    ip_configuration {
        name                =   join("-", ["cdpz", var.environment, each.value.stacc, "dls", each.value.pep_code, "ipc"])
        private_ip_address  =   each.value.pep_ip
        subresource_name    =   each.value.pep_code
        member_name         =   each.value.pep_code
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
      azurerm_storage_account.data_staccs,
      data.azurerm_private_dns_zone.pdnszs
    ]
}
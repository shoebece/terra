locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
  stacc_conts = flatten([
    for stacc_key, stacc in var.staccs : [
        for cont_key, cont in stacc.stconts : {
          key     = join("-", [stacc.stacc, cont])
          stacc   = stacc.stacc
          cont    = cont
        }
    ]
  ])
}

data "azurerm_resource_group" "resgrp" {
  name     = join("-", ["cdpz", var.environment, "landing-rg"])
}

data "azurerm_key_vault" "kv" {
  name                       = var.sandbox_prefix == "" ? join("-", ["cdpz", var.environment, "landing-kv"]) : join("-", ["cdpz", var.environment, var.sandbox_prefix, "landing-kv"])
  resource_group_name        = data.azurerm_resource_group.resgrp.name
}

data "azurerm_key_vault_key" "cmk" {
  name         = join("-", ["cdpz", var.environment, "landing-dls-cmk"])
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = join("-", ["cdpz", var.environment, "landing-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_role_assignment" "umi_to_kv" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.umi.principal_id
}

resource "azurerm_storage_account" "landing_staccs" {
  count                     = length(var.staccs)
  
  name                      = join("", [var.sandbox_prefix, "cdpz", var.environment, var.staccs[count.index].stacc, "dls"])
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  location                  = var.resource_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
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
    virtual_network_subnet_ids  = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]
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

resource "azurerm_storage_container" "cont" {
  for_each              = { for i, stacc_cont in local.stacc_conts: stacc_cont.key => stacc_cont }
  name                  = each.value.cont
  storage_account_name  = join("", [var.sandbox_prefix, "cdpz", var.environment, each.value.stacc, "dls"])
  container_access_type = "private"

  depends_on = [ azurerm_storage_account.landing_staccs ]
}


resource "azurerm_storage_account_customer_managed_key" "stacc_cmk" {
  count                     = length(var.staccs)

  storage_account_id        = azurerm_storage_account.landing_staccs[count.index].id
  key_vault_id              = data.azurerm_key_vault.kv.id
  key_name                  = data.azurerm_key_vault_key.cmk.name
  user_assigned_identity_id = azurerm_user_assigned_identity.umi.id

  depends_on = [
    data.azurerm_resource_group.resgrp
    ,data.azurerm_key_vault.kv
    ,azurerm_storage_account.landing_staccs
    ,data.azurerm_key_vault_key.cmk
    ,azurerm_user_assigned_identity.umi]
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_private_dns_zone" "pdnsz_dls" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_dls" {
    count                           = length(var.staccs)

    name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "pep"])  
    resource_group_name             = local.networking_resource_group_name
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet.id

    custom_network_interface_name   = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "nic"])  

    private_dns_zone_group {
      name = "add_to_azure_private_dns"
      private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_dls.id ]
    }

    private_service_connection {
        name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[0].code, "psc"])
        private_connection_resource_id  = azurerm_storage_account.landing_staccs[count.index].id
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

    depends_on = [
      azurerm_storage_account.landing_staccs,
      data.azurerm_private_dns_zone.pdnsz_dls
    ]
}

data "azurerm_private_dns_zone" "pdnsz_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_blob" {
    count                           = length(var.staccs)

    name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "pep"])  
    resource_group_name             = join("-", ["cdpz", var.environment, "networking-rg"])
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet.id

    custom_network_interface_name   = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "nic"])  

    private_dns_zone_group {
      name = "add_to_azure_private_dns"
      private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_blob.id ]
    }

    private_service_connection {
        name                            = join("-", ["cdpz", var.environment, var.staccs[count.index].stacc, "dls", var.staccs[count.index].pep[1].code, "psc"])
        private_connection_resource_id  = azurerm_storage_account.landing_staccs[count.index].id
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

    depends_on = [
      azurerm_storage_account.landing_staccs,
      data.azurerm_private_dns_zone.pdnsz_blob
    ]
}
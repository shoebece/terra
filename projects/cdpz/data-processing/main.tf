locals {
  networking_resource_group_name = "rg-ila-dl-prod"
  vnet_name                      = "vnet-ila-dl-prod"
}

data "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = local.networking_resource_group_name
}

data "azurerm_subnet" "snet-dbricks-public" {
  name                 = "snet-ila-dbw-public-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-dbricks-private" {
  name                 = "snet-ila-dbw-private-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-default" {
  name                 = "snet-ila-default"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_resource_group" "resgrp" {
  name                 = "rg-ila-dl-prod"
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = "ila-prod-processing-acdb-umi"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_databricks_access_connector" "authorization" {
  name                = "ila-prod-processing-acdb"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  identity {
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi.id]
  }

  tags = merge(var.resource_tags_common, var.resource_tags_spec)

  depends_on = [
    data.azurerm_resource_group.resgrp
  ]
}

data "azurerm_key_vault" "kv" {
  name                       = "kv-ila-dl-prod1"
  resource_group_name        = local.networking_resource_group_name
}

data "azurerm_key_vault_key" "disks_cmk" {
  name                      = "data-dls-cmk-prod"
  key_vault_id              = data.azurerm_key_vault.kv.id
}

resource "azurerm_databricks_workspace" "dbws" {
  name                = "dbw-ila-dl-prod"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  managed_resource_group_name                         = "mg-rg-ila-dl-prod"
  customer_managed_key_enabled                        = false
  infrastructure_encryption_enabled                   = true
  managed_disk_cmk_rotation_to_latest_version_enabled = true
  managed_disk_cmk_key_vault_key_id                   = data.azurerm_key_vault_key.disks_cmk.id
  
  sku = "premium"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    storage_account_name     = "ilaadbwdbfsdls"
    storage_account_sku_name = "Standard_LRS"

    no_public_ip       = true
    virtual_network_id = data.azurerm_virtual_network.vnet.id

    public_subnet_name                                  = data.azurerm_subnet.snet-dbricks-public.name
    public_subnet_network_security_group_association_id = data.azurerm_subnet.snet-dbricks-public.id

    private_subnet_name                                  = data.azurerm_subnet.snet-dbricks-private.name
    private_subnet_network_security_group_association_id = data.azurerm_subnet.snet-dbricks-private.id
  }

  tags = merge(var.resource_tags_common
    , var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      managed_disk_cmk_key_vault_key_id,
      custom_parameters
    ]
  }

  depends_on = [
    data.azurerm_resource_group.resgrp,
    data.azurerm_key_vault.kv,
    data.azurerm_key_vault_key.disks_cmk
  ]
}

# Workspace disk encription set Service Principal access to CMK
# --------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "des_to_kv" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_databricks_workspace.dbws.managed_disk_identity.0.principal_id

  depends_on = [
    azurerm_databricks_workspace.dbws
    ,data.azurerm_key_vault.kv
  ]
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = local.networking_resource_group_name
}

# Private end point ila-dev-processing-dbw-pep
resource "azurerm_private_endpoint" "endpoint" {
  name                            = "ila-prod-processing-dbw-pep"
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet-default.id

  custom_network_interface_name   = "ila-prod-processing-dbw-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
      name                            = "ila-prod-processing-dbw-psc"
      private_connection_resource_id  = azurerm_databricks_workspace.dbws.id
      subresource_names               = ["databricks_ui_api"]
      is_manual_connection            = false
      }

  ip_configuration {
      name                =   "ila-prod-processing-dbw-ipc"
      private_ip_address  =   var.private_endpoint_ip_address
      subresource_name    =   "databricks_ui_api"
      member_name         =   "databricks_ui_api"
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
    azurerm_databricks_workspace.dbws,
    data.azurerm_private_dns_zone.pdnsz
  ]
}
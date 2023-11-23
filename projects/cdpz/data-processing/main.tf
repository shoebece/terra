locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
  vnet_name                      = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = local.networking_resource_group_name
}

data "azurerm_subnet" "snet-dbricks-public" {
  name                 = "processing-dbw-public-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-dbricks-private" {
  name                 = "processing-dbw-private-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-default" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_resource_group" "resgrp" {
  name                 = join("-", ["cdpz", var.environment, "data-processing-rg"])
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = join("-", ["cdpz", var.environment, "processing-acdb-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_databricks_access_connector" "authorization" {
  name                = join("-", ["cdpz", var.environment, "processing-acdb"])
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
  name                       = var.sandbox_prefix == "" ? join("-", ["cdpz", var.environment, "proc-kv"]) : join("-", ["cdpz", var.environment, var.sandbox_prefix, "proc-kv"])
  resource_group_name        = data.azurerm_resource_group.resgrp.name
}

data "azurerm_key_vault_key" "disks_cmk" {
  name                      = join("-", ["cdpz", var.environment, "data-processing-disks-cmk"])
  key_vault_id              = data.azurerm_key_vault.kv.id
}

resource "azurerm_databricks_workspace" "dbws" {
  name                = join("-", ["cdpz", var.environment, "processing-dbw"])
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  managed_resource_group_name                         = join("-", ["cdpz", var.environment, "data-processing-databricks-mrg"])

  customer_managed_key_enabled                        = false
  infrastructure_encryption_enabled                   = true
  managed_disk_cmk_rotation_to_latest_version_enabled = true
  managed_disk_cmk_key_vault_key_id                   = data.azurerm_key_vault_key.disks_cmk.id
  
  sku = "premium"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    storage_account_name     = join("", [var.sandbox_prefix, "cdpz", var.environment, "adbwdbfsdls"])
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

# Private end point cdpz-dev-processing-dbw-pep
resource "azurerm_private_endpoint" "endpoint" {
  name                            = join("-", ["cdpz", var.environment, "processing-dbw-pep"]) 
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet-default.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "processing-dbw-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
      name                            = join("-", ["cdpz", var.environment, "processing-dbw-psc"])
      private_connection_resource_id  = azurerm_databricks_workspace.dbws.id
      subresource_names               = ["databricks_ui_api"]
      is_manual_connection            = false
      }

  ip_configuration {
      name                =   join("-", ["cdpz", var.environment, "processing-dbw-ipc"])
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
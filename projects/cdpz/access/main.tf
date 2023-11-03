locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
  vnet_name                      = join("-", ["cdpz", var.environment, "access-vnet"])
  processing_vnet_name           = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_virtual_network" "vnet" {
  name                = local.vnet_name
  resource_group_name = local.networking_resource_group_name
}

data "azurerm_subnet" "snet-dbricks-public" {
  name                 = "access-dbw-public-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-dbricks-private" {
  name                 = "access-dbw-private-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}

data "azurerm_subnet" "snet-default" {
  name                 = "access-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = local.vnet_name
}


data "azurerm_resource_group" "resgrp" {
  name = join("-", ["cdpz", var.environment, "access-rg"])
}

resource "azurerm_user_assigned_identity" "umi" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = join("-", ["cdpz", var.environment, "access-acdb-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_databricks_access_connector" "authorization" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = join("-", ["cdpz", var.environment, "access-acdb"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi[0].id]
  }

  tags = merge(var.resource_tags_common, var.resource_tags_spec)

  depends_on = [
    data.azurerm_resource_group.resgrp
    , azurerm_user_assigned_identity.umi
  ]
}

data "azurerm_key_vault" "kv" {
  name                = var.sandbox_prefix == "" ? join("-", ["cdpz", var.environment, "access-kv"]) : join("-", ["cdpz", var.environment, var.sandbox_prefix, "access-kv"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

data "azurerm_key_vault_key" "disks-cmk" {
  name         = join("-", ["cdpz", var.environment, "access-disks-cmk"])
  key_vault_id = data.azurerm_key_vault.kv.id
}

resource "azurerm_databricks_workspace" "dbws" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = join("-", ["cdpz", var.environment, "access-dbw"])
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  managed_resource_group_name = join("-", ["cdpz", var.environment, "access-databricks-mrg"])

  customer_managed_key_enabled                        = false
  infrastructure_encryption_enabled                   = true
  managed_disk_cmk_rotation_to_latest_version_enabled = true
  managed_disk_cmk_key_vault_key_id                   = data.azurerm_key_vault_key.disks-cmk.id

  sku = "premium"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    storage_account_name     = join("", [var.sandbox_prefix, "cdpz", var.environment, "adbwaccessdls"])
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
    data.azurerm_key_vault_key.disks-cmk
  ]
}

# Workspace disk encription set Service Principal access to CMK
# --------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "des-to-kv" {
  count                = (var.environment == "prod" ? 1 : 0)
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_databricks_workspace.dbws[0].managed_disk_identity.0.principal_id

  depends_on = [
    azurerm_databricks_workspace.dbws
    , data.azurerm_key_vault.kv
  ]
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = local.networking_resource_group_name
}

# Private end point cdpz-dev-access-dbw-pep
resource "azurerm_private_endpoint" "endpoint" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = join("-", ["cdpz", var.environment, "access-dbw-pep"])
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = join("-", ["cdpz", var.environment, "access-dbw-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                           = join("-", ["cdpz", var.environment, "access-dbw-psc"])
    private_connection_resource_id = azurerm_databricks_workspace.dbws[0].id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = join("-", ["cdpz", var.environment, "access-dbw-ipc"])
    private_ip_address = var.databricks_auth_pep_ip
    subresource_name   = "databricks_ui_api"
    member_name        = "databricks_ui_api"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    azurerm_databricks_workspace.dbws,
    data.azurerm_private_dns_zone.pdnsz
  ]
}
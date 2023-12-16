locals {
  networking_resource_group_name = "cdmz-networking-rg"
}

data "azurerm_resource_group" "resgrp" {
  name     = "cdmz-management-rg"
}

data "azurerm_resource_group" "artifactoryresgrp" {
  name     = "cdmz-artifactory-rg"
}

data "azurerm_virtual_network" "vnet" {
  name                = "cdmz-management-vnet"
  resource_group_name = local.networking_resource_group_name
}

data "azurerm_subnet" "snet-dbricks-public" {
  name                 = "management-dbw-public-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "snet-dbricks-private" {
  name                 = "management-dbw-private-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

data "azurerm_subnet" "snet-default" {
  name                 = "management-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = data.azurerm_virtual_network.vnet.name
}

# User Managed idntity for databricks connector to set permissions i separate project
resource "azurerm_user_assigned_identity" "acdb-umi" {
  name                = "cdmz-management-acdb-umi"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_databricks_access_connector" "authorization" {
  name                = "cdmz-management-acdb"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.acdb-umi.id]
  }

  tags = merge(var.resource_tags_common, var.resource_tags_spec)

  depends_on = [
    data.azurerm_resource_group.resgrp
  ]
}

data "azurerm_key_vault" "kv" {
  name                = var.sandbox_prefix == "" ? "cdmz-management-kv" : "cdmz-${var.sandbox_prefix}-management-kv"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

data "azurerm_key_vault" "artifactorykv" {
  name                = var.sandbox_prefix == "" ? "cdmz-artifactory-kv" : "cdmz-${var.sandbox_prefix}-management-kv"
  resource_group_name = data.azurerm_resource_group.artifactoryresgrp.name
}

data "azurerm_key_vault_key" "disks-cmk" {
  name         = "cdmz-management-disks-cmk"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_key" "artifactory-disks-cmk" {
  name         = "cdmz-artifactory-disks-cmk"
  key_vault_id = data.azurerm_key_vault.artifactorykv.id
}

data "azurerm_key_vault_key" "managed-dbfs-cmk" {
  name         = "cdmz-management-dbfs-cmk"
  key_vault_id = data.azurerm_key_vault.kv.id
}

data "azurerm_key_vault_key" "artifactory-dbfs-cmk" {
  name         = "cdmz-artifactory-dbfs-cmk"
  key_vault_id = data.azurerm_key_vault.artifactorykv.id
}

resource "azurerm_user_assigned_identity" "meta-umi" {
  name                = "cdmz-metastore-umi"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_role_assignment" "meta-umi-to-kv" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.meta-umi.principal_id
}

resource "azurerm_user_assigned_identity" "artifactory-umi" {
  name                = "cdmz-artifactory-umi"
  resource_group_name = data.azurerm_resource_group.artifactoryresgrp.name
  location            = var.resource_location
}

resource "azurerm_role_assignment" "artifactory-umi-to-kv" {
  scope                = data.azurerm_key_vault.artifactorykv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_user_assigned_identity.artifactory-umi.principal_id
}

resource "azurerm_storage_account" "managed_dls" {
  name                      = join("", [var.sandbox_prefix, "cdmzadbmetastoredls"])
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
      azurerm_user_assigned_identity.meta-umi.id
    ]
  }

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]
  }

  tags = merge(
    var.resource_tags_common, var.resource_tags_spec
  )

  depends_on = [
    azurerm_user_assigned_identity.meta-umi
    ,azurerm_role_assignment.meta-umi-to-kv
  ]
}

resource "azurerm_storage_container" "cont" {
  name                  = "metastore"
  storage_account_name  = azurerm_storage_account.managed_dls.name
  container_access_type = "private"

  depends_on = [ azurerm_storage_account.managed_dls ]
}

resource "azurerm_storage_account_customer_managed_key" "stacc_cmk" {
  storage_account_id        = azurerm_storage_account.managed_dls.id
  key_vault_id              = data.azurerm_key_vault.kv.id
  key_name                  = data.azurerm_key_vault_key.managed-dbfs-cmk.name
  user_assigned_identity_id = azurerm_user_assigned_identity.meta-umi.id

  depends_on = [
      azurerm_storage_account.managed_dls
    , azurerm_user_assigned_identity.meta-umi
    , azurerm_role_assignment.meta-umi-to-kv]
}

resource "azurerm_storage_account" "artifactory_dls" {
  name                      = join("", [var.sandbox_prefix, "cdmzartifactorydls"])
  resource_group_name       = data.azurerm_resource_group.artifactoryresgrp.name
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
      azurerm_user_assigned_identity.artifactory-umi.id
    ]
  }

  network_rules {
    default_action = "Deny"
    virtual_network_subnet_ids = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra",
    "/subscriptions/7fafdbc0-65a3-4508-a1da-2bbbdbc2299b/resourceGroups/cdmz-networking-rg/providers/Microsoft.Network/virtualNetworks/cdmz-management-vnet/subnets/management-default-snet",
    "/subscriptions/7fafdbc0-65a3-4508-a1da-2bbbdbc2299b/resourceGroups/cdmz-networking-rg/providers/Microsoft.Network/virtualNetworks/cdmz-management-vnet/subnets/management-dbw-private-snet",
    "/subscriptions/7fafdbc0-65a3-4508-a1da-2bbbdbc2299b/resourceGroups/cdmz-networking-rg/providers/Microsoft.Network/virtualNetworks/cdmz-management-vnet/subnets/management-dbw-public-snet"]
  }

  tags = merge(
    var.resource_tags_common, var.resource_tags_spec
  )

  depends_on = [
    azurerm_user_assigned_identity.artifactory-umi
  ]
}

resource "azurerm_storage_container" "artifactory_cont" {
  count                 = length(var.artifactory_conts)
  name                  = var.artifactory_conts[count.index]
  storage_account_name  = azurerm_storage_account.artifactory_dls.name
  container_access_type = "private"

  depends_on = [ azurerm_storage_account.artifactory_dls ]
}

resource "azurerm_storage_account_customer_managed_key" "art_stacc_cmk" {
  storage_account_id        = azurerm_storage_account.artifactory_dls.id
  key_vault_id              = data.azurerm_key_vault.artifactorykv.id
  key_name                  = data.azurerm_key_vault_key.artifactory-dbfs-cmk.name
  user_assigned_identity_id = azurerm_user_assigned_identity.artifactory-umi.id

  depends_on = [
      azurerm_storage_account.artifactory_dls
    , azurerm_user_assigned_identity.artifactory-umi
    , azurerm_role_assignment.artifactory-umi-to-kv]
}


resource "azurerm_databricks_workspace" "dbws" {
  name                = "cdmz-management-dbw"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  managed_resource_group_name = "cdmz-management-databricks-mrg"

  customer_managed_key_enabled                        = false
  infrastructure_encryption_enabled                   = true
  managed_disk_cmk_rotation_to_latest_version_enabled = true
  managed_disk_cmk_key_vault_key_id                   = data.azurerm_key_vault_key.disks-cmk.id

  sku = "premium"

  public_network_access_enabled         = false
  network_security_group_rules_required = "NoAzureDatabricksRules"

  custom_parameters {
    storage_account_name     = join("", [var.sandbox_prefix, "cdmzdbwdbfsdls"])
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
}

# Workspace disk encription set Service Principal access to CMK
# --------------------------------------------------------------------------------------
resource "azurerm_role_assignment" "des-to-kv" {
  scope                = data.azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Crypto Service Encryption User"
  principal_id         = azurerm_databricks_workspace.dbws.managed_disk_identity.0.principal_id

  depends_on = [
    azurerm_databricks_workspace.dbws
  ]
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = local.networking_resource_group_name
}

# Private end point cdpz-dev-access-dbw-pep
resource "azurerm_private_endpoint" "endpoint_ui" {
  name                = "cdmz-dbw-backend-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-dbw-backend-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  } 

  private_service_connection {
    name                           = "cdmz-dbw-backend-psc"
    private_connection_resource_id = azurerm_databricks_workspace.dbws.id
    subresource_names              = ["databricks_ui_api"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-dbw-backend-ipc"
    private_ip_address = var.databricks_ui_pep_ip
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
    data.azurerm_private_dns_zone.pdnsz,
    data.azurerm_subnet.snet-default
  ]
}

resource "azurerm_private_endpoint" "endpoint_auth" {
  name                = "cdmz-dbw-authentication-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-dbw-authentication-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  } 

  private_service_connection {
    name                           = "cdmz-dbw-authentication-psc"
    private_connection_resource_id = azurerm_databricks_workspace.dbws.id
    subresource_names              = ["browser_authentication"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-dbw-authentication-ipc"
    private_ip_address = var.databricks_auth_pep_ip
    subresource_name   = "browser_authentication"
    member_name        = "uaenorth"
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
    azurerm_databricks_workspace.dbws
    ,data.azurerm_private_dns_zone.pdnsz
  ]
}

# -------------------------------------Artifactory----------------------------------------------
data "azurerm_user_assigned_identity" "man-umi" {
  name                = "cdmz-management-acdb-umi"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "databricks_storage_credential" "man_stacc_cred" {
  name = "cdm-man-storage-credentials"
  azure_managed_identity {
    access_connector_id = "/subscriptions/7fafdbc0-65a3-4508-a1da-2bbbdbc2299b/resourceGroups/cdmz-management-rg/providers/Microsoft.Databricks/accessConnectors/cdmz-management-acdb"
    managed_identity_id = data.azurerm_user_assigned_identity.man-umi.id
  }

  depends_on = [
    data.azurerm_databricks_workspace.man_dbw,
    data.azurerm_user_assigned_identity.man-umi
  ]
}

resource "databricks_external_location" "artifactory_ext_loc" {
  count = length(var.artifactory_conts)
  name = join("-", ["cdm" , "artifactory", var.artifactory_conts[count.index], "ext-loc"])
  url = join("", ["abfss://", var.artifactory_conts[count.index], "@", "cdmzartifactorydls.dfs.core.windows.net"])

  credential_name = databricks_storage_credential.man_stacc_cred.id
  depends_on = [ databricks_storage_credential.man_stacc_cred ]
}
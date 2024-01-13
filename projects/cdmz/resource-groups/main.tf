resource "azurerm_resource_provider_registration" "pview_provider" {
  count = (var.deploy_pview_provider ? 1 : 0)
  name = "Microsoft.Purview"
}

resource "azurerm_resource_group" "management-rg" {
  name     = "cdmz-management-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "mgmt-fivetran-rg" {
  name     = "cdmz-mgmt-fivetran-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_key_vault" "management-kv" {
  name                       = "cdmz-management-kv"
  resource_group_name        = azurerm_resource_group.management-rg.name
  location                   = var.resource_location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 60
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = var.resource_tags_common
  public_network_access_enabled = "true"

  network_acls {
    default_action  = "Deny"
    bypass          = "AzureServices"
    virtual_network_subnet_ids = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]
  }

  depends_on = [azurerm_resource_group.management-rg]
}

resource "azurerm_key_vault_key" "management-disks-cmk" {
  name         = "cdmz-management-disks-cmk"
  key_vault_id = azurerm_key_vault.management-kv.id
  key_type     = "RSA"
  key_size     = 4096
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  rotation_policy {
    automatic {
      time_after_creation = "P1Y"
    }
  }

  depends_on = [azurerm_key_vault.management-kv]
}

resource "azurerm_key_vault_key" "management-dbfs-cmk" {
  name         = "cdmz-management-dbfs-cmk"
  key_vault_id = azurerm_key_vault.management-kv.id
  key_type     = "RSA"
  key_size     = 4096
  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
  rotation_policy {
    automatic {
      time_after_creation = "P1Y"
    }
  }

  depends_on = [azurerm_key_vault.management-kv]
}

resource "azurerm_key_vault" "mgmt-fivetran-kv" {
  name                       = "cdmz-mgmt-fivetran-kv"
  resource_group_name        = azurerm_resource_group.mgmt-fivetran-rg.name
  location                   = var.resource_location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 60
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = var.resource_tags_common
  public_network_access_enabled = "true"

  network_acls {
    default_action  = "Deny"
    bypass          = "AzureServices"
    virtual_network_subnet_ids = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]
  }

  depends_on = [azurerm_resource_group.mgmt-fivetran-rg.name]
}

resource "azurerm_resource_group" "governance-rg" {
  name     = "cdmz-governance-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "shared-shir-rg" {
  name     = "cdmz-shared-shir-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "fivetran-integration-rg" {
  name     = "cdmz-fivetran-integration-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "monitoring-rg" {
  name     = "cdmz-monitoring-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "networking-rg" {
  name     = "cdmz-networking-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "pbi-gateway-rg" {
  name     = "cdmz-pbi-gateway-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}


#--------------------------------------Artifactory Resource Group ---------------------
resource "azurerm_resource_group" "artifactory-rg" {
  name     = "cdmz-artifactory-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}
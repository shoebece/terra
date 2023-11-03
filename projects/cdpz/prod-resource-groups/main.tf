locals {
  devops_subnet_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"
}

# Creted in common resource group project - to avoid recreation
# ## Production specyfic resource groups
# ## access resource group
# resource "azurerm_resource_group" "access-rg" {
#   name     = "cdpz-prod-access-rg"
#   location = var.resource_location
#   tags     = var.resource_tags_common
# }

# resource "azurerm_key_vault" "access-kv" {
#   name                       = "cdpz-prod-access-kv"
#   resource_group_name        = azurerm_resource_group.access-rg.name
#   location                   = var.resource_location
#   tenant_id                  = var.tenant_id
#   sku_name                   = "standard"
#   soft_delete_retention_days = 60
#   purge_protection_enabled   = true
#   enable_rbac_authorization  = true
#   tags                       = var.resource_tags_common

#   network_acls {
#     default_action  = "Deny"
#     bypass          = "AzureServices"
#     virtual_network_subnet_ids = [local.devops_subnet_id] 
#   }

#   depends_on = [azurerm_resource_group.access-rg]
# }

# resource "azurerm_key_vault_key" "access-disks-cmk" {
#   name         = "cdpz-prod-access-disks-cmk"
#   key_vault_id = azurerm_key_vault.access-kv.id
#   key_type     = "RSA"
#   key_size     = 4096
#   key_opts = [
#     "decrypt",
#     "encrypt",
#     "sign",
#     "unwrapKey",
#     "verify",
#     "wrapKey"
#   ]
#   rotation_policy {
#     automatic {
#       time_after_creation = "P1Y"
#     }
#   }

#   depends_on = [azurerm_key_vault.access-kv]
# }

## global processing resource group
resource "azurerm_resource_group" "g-proc-rg" {
  name     = "cdpz-global-processing-rg"
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_key_vault" "g-proc-kv" {
  name                       = "cdpz-global-proc-kv"
  resource_group_name        = azurerm_resource_group.g-proc-rg.name
  location                   = var.resource_location
  tenant_id                  = var.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 60
  purge_protection_enabled   = true
  enable_rbac_authorization  = true
  tags                       = var.resource_tags_common

  network_acls {
    default_action  = "Deny"
    bypass          = "AzureServices"
    virtual_network_subnet_ids = [local.devops_subnet_id] 
  }

  depends_on = [azurerm_resource_group.g-proc-rg]
}

resource "azurerm_key_vault_key" "access-disks-cmk" {
  name         = "cdpz-global-processing-disks-cmk"
  key_vault_id = azurerm_key_vault.g-proc-kv.id
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

  depends_on = [azurerm_key_vault.g-proc-kv]
}
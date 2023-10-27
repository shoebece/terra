locals {
  devops_subnet_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"
}
resource "azurerm_resource_provider_registration" "db_provider" {
  count = (var.deploy_db_provider ? 1 : 0)
  name  = "Microsoft.Databricks"
}

resource "azurerm_resource_provider_registration" "oper_insights_provider" {
  name = "Microsoft.OperationalInsights"
}

resource "azurerm_resource_provider_registration" "vnet_provider" {
  count = (var.deploy_vnet_provider ? 1 : 0)
  name = "Microsoft.Network"
}

resource "azurerm_resource_provider_registration" "kv_provider" {
  count = (var.deploy_kv_provider ? 1 : 0)
  name = "Microsoft.KeyVault"
}


resource "azurerm_resource_group" "data-processing-rg" {
  name     = join("-", ["cdpz", var.environment, "data-processing-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "access-rg" {
  name     = join("-", ["cdpz", var.environment, "access-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_key_vault" "access-kv" {
  name                       = join("-", ["cdpz", var.environment, "access-kv"])#bez testprefixu bedzie lipa
  resource_group_name        = azurerm_resource_group.access-rg.name
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

  depends_on = [azurerm_resource_group.orchestration-and-ingestion-rg]
}

resource "azurerm_key_vault_key" "access-disks-cmk" {
  name         = join("-", ["cdpz", var.environment, "access-disks-cmk"])
  key_vault_id = azurerm_key_vault.access-kv.id
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

  depends_on = [azurerm_key_vault.access-kv]
}

resource "azurerm_resource_group" "sharing-rg" {
  name     = join("-", ["cdpz", var.environment, "sharing-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "orchestration-and-ingestion-rg" {
  name     = join("-", ["cdpz", var.environment, "orchestration-and-ingestion-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "landing-rg" {
  name     = join("-", ["cdpz", var.environment, "landing-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "data-storage-rg" {
  name     = join("-", ["cdpz", var.environment, "data-storage-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "data-streaming-rg" {
  name     = join("-", ["cdpz", var.environment, "data-streaming-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "monitoring-rg" {
  name     = join("-", ["cdpz", var.environment, "monitoring-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_resource_group" "networking-rg" {
  name     = join("-", ["cdpz", var.environment, "networking-rg"])
  location = var.resource_location
  tags     = var.resource_tags_common
}

resource "azurerm_key_vault" "orch-kv" {
  name                       = join("-", ["cdpz", var.environment, "orchestr-kv"])
  resource_group_name        = azurerm_resource_group.orchestration-and-ingestion-rg.name
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

  depends_on = [azurerm_resource_group.orchestration-and-ingestion-rg]
}

resource "azurerm_key_vault" "proc-kv" {
  name                       = join("-", ["cdpz", var.environment, "proc-kv"])
  resource_group_name        = azurerm_resource_group.data-processing-rg.name
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

  depends_on = [azurerm_resource_group.data-processing-rg]
}

resource "azurerm_key_vault_key" "data-processing-disks-cmk" {
  name         = join("-", ["cdpz", var.environment, "data-processing-disks-cmk"])
  key_vault_id = azurerm_key_vault.proc-kv.id
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

  depends_on = [azurerm_key_vault.proc-kv]
}


resource "azurerm_key_vault" "landing-kv" {
  name                       = join("-", ["cdpz", var.environment, "landing-kv"])
  resource_group_name        = azurerm_resource_group.landing-rg.name
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

  depends_on = [azurerm_resource_group.landing-rg]
}

resource "azurerm_key_vault_key" "landing-dls-cmk" {
  name         = join("-", ["cdpz", var.environment, "landing-dls-cmk"])
  key_vault_id = azurerm_key_vault.landing-kv.id
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

  depends_on = [azurerm_key_vault.landing-kv]
}


resource "azurerm_key_vault" "data-kv" {
  name                       = join("-", ["cdpz", var.environment, "data-kv"])
  resource_group_name        = azurerm_resource_group.data-storage-rg.name
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

  depends_on = [azurerm_resource_group.data-storage-rg]
}

resource "azurerm_key_vault_key" "data-storage-dls-cmk" {
  name         = join("-", ["cdpz", var.environment, "data-storage-dls-cmk"])
  key_vault_id = azurerm_key_vault.data-kv.id
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

  depends_on = [azurerm_key_vault.data-kv]
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.71.0"
    }
    databricks = {
      source = "databricks/databricks"
      version = "1.27.0"
    }
  }
  backend "azurerm" {}
}

provider "azurerm" {
  alias           = "cdmz"

  tenant_id       = var.tenant_id
  subscription_id = var.cdmz_subscription_id
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "dev"

  tenant_id       = var.tenant_id
  subscription_id = var.cdpz_dev_subscription_id
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "uat"

  tenant_id       = var.tenant_id
  subscription_id = var.cdpz_uat_subscription_id
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "prod"

  tenant_id       = var.tenant_id
  subscription_id = var.cdpz_prod_subscription_id
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_databricks_workspace" "dev_dbw" {
  provider            = azurerm.dev
  name                = "cdpz-dev-processing-dbw"
  resource_group_name = "cdpz-dev-data-processing-rg"
}

provider "databricks" {
  alias                       = "devdbw"
  host                        = data.azurerm_databricks_workspace.dev_dbw.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.dev_dbw.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}

data "azurerm_databricks_workspace" "uat_dbw" {
  provider            = azurerm.uat
  name                = "cdpz-uat-processing-dbw"
  resource_group_name = "cdpz-uat-data-processing-rg"
}

provider "databricks" {
  alias                       = "uatdbw"
  host                        = data.azurerm_databricks_workspace.uat_dbw.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.uat_dbw.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}

data "azurerm_databricks_workspace" "prod_dbw" {
  provider            = azurerm.prod
  name                = "cdpz-prod-processing-dbw"
  resource_group_name = "cdpz-prod-data-processing-rg"
}

provider "databricks" {
  alias                       = "proddbw"
  host                        = data.azurerm_databricks_workspace.prod_dbw.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.prod_dbw.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}

data "azurerm_databricks_workspace" "global_dbw" {
  provider            = azurerm.prod
  name                = "cdpz-global-processing-dbw"
  resource_group_name = "cdpz-global-processing-rg"
}

provider "databricks" {
  alias                       = "globaldbw"
  host                        = data.azurerm_databricks_workspace.global_dbw.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.global_dbw.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}

data "azurerm_databricks_workspace" "access" {
  provider            = azurerm.prod
  name                = "cdpz-prod-access-dbw"
  resource_group_name = "cdpz-prod-access-rg"
}

provider "databricks" {
  alias                       = "access"
  host                        = data.azurerm_databricks_workspace.access.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.access.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}
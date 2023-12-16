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
  tenant_id       = var.tenant_id
  subscription_id = var.subscription_id

  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

data "azurerm_databricks_workspace" "man_dbw" {
  name                = "cdmz-management-dbw"
  resource_group_name = "cdmz-management-rg"
}

provider "databricks" {
  host                        = data.azurerm_databricks_workspace.man_dbw.workspace_url
  azure_workspace_resource_id = data.azurerm_databricks_workspace.man_dbw.id
  account_id                  = "af7f851a-1d3e-425a-97a5-43b295231b90" 
}
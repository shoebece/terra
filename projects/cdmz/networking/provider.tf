terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.71.0"
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

provider "azurerm" {
  alias           = "infrateam"

  tenant_id       = var.tenant_id
  subscription_id = "1691759c-bec8-41b8-a5eb-03c57476ffdb"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
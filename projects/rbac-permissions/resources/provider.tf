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
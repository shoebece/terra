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

provider "azurerm" {
  alias           = "Ecommerce"

  tenant_id       = var.tenant_id
  subscription_id = "039efcb8-56e2-459b-ad3c-68c086e8feb9"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "BerthPlanningApplication"

  tenant_id       = var.tenant_id
  subscription_id = "623cd43f-a4c3-4dbc-881c-3ba2804a8a4c"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "DPWFoundationalServicesProd"

  tenant_id       = var.tenant_id
  subscription_id = "368014ab-c35d-4615-a165-842d87aec6f5"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "CargoesFlow"

  tenant_id       = var.tenant_id
  subscription_id = "226040e8-5c0e-44f2-8915-1afed1732440"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
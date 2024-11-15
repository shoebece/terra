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

provider "azurerm" {
  alias           = "TradeFinance"

  tenant_id       = var.tenant_id
  subscription_id = "f3d35456-12f8-4897-a1c3-2bb59e949ec5"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "CargoesLogistics"

  tenant_id       = var.tenant_id
  subscription_id = "a3e25ce2-341c-4f68-b42d-0ec5f349a526"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}


provider "azurerm" {
  alias           = "BusinessAnalytics"

  tenant_id       = var.tenant_id
  subscription_id = "3c44ba2d-eba5-4d51-adb8-8614bf03bd29"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "NAU"

  tenant_id       = var.tenant_id
  subscription_id = "ededa550-54e3-4ac7-a6b0-bca51f3c1495"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "CCSMEA"

  tenant_id       = var.tenant_id
  subscription_id = "ad86c834-0651-4e48-8c88-2cf8289e2fe7"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "CCSGlobal"

  tenant_id       = var.tenant_id
  subscription_id = "7076703f-57ca-4c30-9d69-94c008f7a470"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "DTWorld"

  tenant_id       = var.tenant_id
  subscription_id = "56a6b4b1-7256-4834-9817-e27c75f1ae05"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "POEMS"

  tenant_id       = var.tenant_id
  subscription_id = "1f5e2bb0-70cd-430f-9fde-ecd3b07a0769"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "DryDocks"

  tenant_id       = var.tenant_id
  subscription_id = "7c422b28-6937-4df7-895e-c19e321257cb"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "CargoesRunner"

  tenant_id       = var.tenant_id
  subscription_id = "99a847a3-1033-4a6d-a9bb-41a087e8c982"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "orms"

  tenant_id       = var.tenant_id
  subscription_id = "c1ed99db-01ec-4593-92d3-cf4a26a19555"
  
  storage_use_azuread = true
  skip_provider_registration = true

  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "azurerm" {
  alias           = "DPWorldGlobal"

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
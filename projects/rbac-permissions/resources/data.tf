#------------------------------------------------------------------------------------------------
# Resource groups
data "azurerm_subscription" "cmdz_sub" {
  provider = azurerm.cdmz
}

data "azurerm_subscription" "dev_cdpz_sub" {
  provider = azurerm.dev
}

data "azurerm_subscription" "uat_cdpz_sub" {
  provider = azurerm.uat
}

data "azurerm_subscription" "prod_cdpz_sub" {
  provider = azurerm.prod
}

#------------------------------------------------------------------------------------------------
# Resource groups

#---------------------------
# DEV
# Data storage
data "azurerm_resource_group" "dev-storage-rg" {
  provider  = azurerm.dev
  name      = "cdpz-dev-data-storage-rg"
}

# Landing
data "azurerm_resource_group" "dev-landing-rg" {
  provider  = azurerm.dev
  name      = "cdpz-dev-landing-rg"
}

# Data processing
data "azurerm_resource_group" "dev-processing-rg" {
  provider  = azurerm.dev
  name      = "cdpz-dev-data-processing-rg"
}

# Sharing
data "azurerm_resource_group" "dev-sharing" {
  provider  = azurerm.dev
  name      = "cdpz-dev-sharing-rg"
}

# Orchestration and igestion
data "azurerm_resource_group" "dev-orch-and-ingest-rg" {
  provider  = azurerm.dev
  name      = "cdpz-dev-orchestration-and-ingestion-rg"
}

# Synapse workspace
data "azurerm_synapse_workspace" "dev_synapse_ws" {
  provider            = azurerm.dev
  resource_group_name = "cdpz-dev-sharing-rg"
  name                = "cdpz-dev-sharing-synapse"
}

# UAT
# Data storage
data "azurerm_resource_group" "uat-storage-rg" {
  provider  = azurerm.uat
  name      = "cdpz-uat-data-storage-rg"
}

# Landing
data "azurerm_resource_group" "uat-landing-rg" {
  provider  = azurerm.uat
  name      = "cdpz-uat-landing-rg"
}

# Data processing
data "azurerm_resource_group" "uat-processing-rg" {
  provider  = azurerm.uat
  name      = "cdpz-uat-data-processing-rg"
}

# Sharing
data "azurerm_resource_group" "uat-sharing" {
  provider  = azurerm.uat
  name      = "cdpz-uat-sharing-rg"
}

# Orchestration and igestion
data "azurerm_resource_group" "uat-orch-and-ingest-rg" {
  provider  = azurerm.uat
  name      = "cdpz-uat-orchestration-and-ingestion-rg"
}

# Synapse workspace
data "azurerm_synapse_workspace" "uat_synapse_ws" {
  provider            = azurerm.uat
  resource_group_name = "cdpz-uat-sharing-rg"
  name                = "cdpz-uat-sharing-synapse"
}

# PROD
# Data storage
data "azurerm_resource_group" "prod-storage-rg" {
  provider  = azurerm.prod
  name      = "cdpz-prod-data-storage-rg"
}

# Landing
data "azurerm_resource_group" "prod-landing-rg" {
  provider  = azurerm.prod
  name      = "cdpz-prod-landing-rg"
}

# Data processing
data "azurerm_resource_group" "prod-processing-rg" {
  provider  = azurerm.prod
  name      = "cdpz-prod-data-processing-rg"
}

# Sharing
data "azurerm_resource_group" "prod-sharing" {
  provider  = azurerm.prod
  name      = "cdpz-prod-sharing-rg"
}

# Orchestration and igestion
data "azurerm_resource_group" "prod-orch-and-ingest-rg" {
  provider  = azurerm.prod
  name      = "cdpz-prod-orchestration-and-ingestion-rg"
}

# Synapse workspace
data "azurerm_synapse_workspace" "prod_synapse_ws" {
  provider            = azurerm.prod
  resource_group_name = "cdpz-prod-sharing-rg"
  name                = "cdpz-prod-sharing-synapse"
}

# CI-CD
data "azurerm_resource_group" "ci-cd-rg" {
  provider  = azurerm.cdmz
  name      = "cdmz-cicd-rg"
}
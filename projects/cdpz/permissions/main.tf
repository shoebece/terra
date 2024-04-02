#------------------------------------------------------------------------------------------------
# Resource groups

# Data storage
data "azurerm_resource_group" "data-storage-rg" {
  name      = join("-", ["cdpz", var.environment, "data-storage-rg"])
}

# Landing
data "azurerm_resource_group" "landing-rg" {
  name      = join("-", ["cdpz", var.environment, "landing-rg"])
}

# Orchestration and igestion
data "azurerm_resource_group" "orch-and-ingest-rg" {
  name      = join("-", ["cdpz", var.environment, "orchestration-and-ingestion-rg"])
}

# Processing
data "azurerm_resource_group" "processing-rg" {
  name      = join("-", ["cdpz", var.environment, "data-processing-rg"])
}

#------------------------------------------------------------------------------------------------
# Service principals

# Azure Data Factory User Managed Identity
data "azurerm_user_assigned_identity" "adf-umi" {
  name                = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-umi"])
  resource_group_name = data.azurerm_resource_group.orch-and-ingest-rg.name
}

# Processing databricks connector User Managed Identity
data "azurerm_user_assigned_identity" "proc-dbw-conn-umi" {
  name                = join("-", ["cdpz", var.environment, "processing-acdb-umi"])
  resource_group_name = join("-", ["cdpz", var.environment, "data-processing-rg"])
}

# Access databricks connector User Managed Identity
data "azurerm_user_assigned_identity" "acc-dbw-conn-umi" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = join("-", ["cdpz", var.environment, "access-acdb-umi"])
  resource_group_name = join("-", ["cdpz", var.environment, "access-rg"])
}

# Streaming UMI
data "azurerm_user_assigned_identity" "stream-umi" {
  name                = join("-", ["cdpz", var.environment, "data-streaming-ehns-umi"])
  resource_group_name = join("-", ["cdpz", var.environment, "data-streaming-rg"])
}

#------------------------------------------------------------------------------------------------
# Permissions

# ADF UMI is Storage Blob Data Contributor on Data storage RG
resource "azurerm_role_assignment" "adf-to-data-storage" {
  scope                = data.azurerm_resource_group.data-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# ADF UMI is Storage Blob Data Contributor on landing RG
resource "azurerm_role_assignment" "adf-to-landing" {
  scope                = data.azurerm_resource_group.landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# ADF UMI is Data Factory Contributor on Orchestration and igestion RG
resource "azurerm_role_assignment" "adf-data-factory_contr" {
  scope                = data.azurerm_resource_group.orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# ADF UMI is Key Vault Secrets Officer on Orchestration and igestion RG
resource "azurerm_role_assignment" "adf-key-vault-officer" {
  scope                = data.azurerm_resource_group.orch-and-ingest-rg.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# Processing databricks connector User Managed Identity Storage Blob Data Contributor on landing
resource "azurerm_role_assignment" "proc-db-to-landing" {
  scope                = data.azurerm_resource_group.landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.proc-dbw-conn-umi.principal_id
}

# Processing databricks connector User Managed Identity Storage Blob Data Contributor on data storage
resource "azurerm_role_assignment" "proc-db-to-data-storage" {
  scope                = data.azurerm_resource_group.data-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.proc-dbw-conn-umi.principal_id
}

# Access databricks connector User Managed Identity Storage Blob Data Contributor on data storage
resource "azurerm_role_assignment" "acc-db-to-data-storage" {
  count                = (var.environment == "prod" ? 1 : 0)
  scope                = data.azurerm_resource_group.data-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.acc-dbw-conn-umi[0].principal_id
}

# Stream User Managed Identity Storage Blob Data Contributor on landing
resource "azurerm_role_assignment" "stream-to-landing" {
  scope                = data.azurerm_resource_group.landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.stream-umi.principal_id
}

# CDMZ identities permissions
#------------------------------------------------------------------------------------------------
# CDMZ Identity
# Management databricks connector User Managed Identity
data "azurerm_user_assigned_identity" "man-dbw-conn-umi" {
  provider            = azurerm.cdmz
  name                = "cdmz-management-acdb-umi"
  resource_group_name = "cdmz-management-rg"
}

#------------------------------------------------------------------------------------------------
# Permissions

# Management databricks connector User Managed Identity Storage Blob Data Contributor on data storage
resource "azurerm_role_assignment" "man-db-to-data-storage" {
  scope                = data.azurerm_resource_group.data-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.man-dbw-conn-umi.principal_id
}

# Management databricks connector User Managed Identity Storage Blob Data Contributor on landing
resource "azurerm_role_assignment" "man-db-to-landing" {
  scope                = data.azurerm_resource_group.landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.man-dbw-conn-umi.principal_id
}

resource "azurerm_role_assignment" "databricks-sp-to-proc-kv" {
  scope                = data.azurerm_resource_group.processing-rg.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = "b2da8212-90d4-45e0-a84e-aae2f5ca9964"
}
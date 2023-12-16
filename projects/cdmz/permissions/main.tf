#------------------------------------------------------------------------------------------------
# Resource groups
# Managemtnt
data "azurerm_resource_group" "management-rg" {
  name      = "cdmz-management-rg"
}

# Fivetran
data "azurerm_resource_group" "fr-rg" {
  name      = "cdmz-fivetran-integration-rg"
}

# Shir
data "azurerm_resource_group" "shir-rg" {
  name      = "cdmz-shared-shir-rg"
}

# PBI-Gateway
data "azurerm_resource_group" "pbi-rg" {
  name      = "cdmz-pbi-gateway-rg"
}

# Artifactory
data "azurerm_resource_group" "artifactory-rg" {
  name      = "cdmz-artifactory-rg"
}

#CDMZ Identity
# Management databricks connector User Managed Identity
data "azurerm_user_assigned_identity" "man-dbw-conn-umi" {
  name                = "cdmz-management-acdb-umi"
  resource_group_name = data.azurerm_resource_group.management-rg.name
}

# ADF
data "azurerm_user_assigned_identity" "adf-umi" {
  name                = "cdmz-shared-shir-adf-id"
  resource_group_name = data.azurerm_resource_group.shir-rg.name
}

#------------------------------------------------------------------------------------------------
# Permissions
# Management databricks connector User Managed Identity Storage Blob Data Contributor on metastore storage
resource "azurerm_role_assignment" "man-db-to-meta" {
  scope                = data.azurerm_resource_group.management-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.man-dbw-conn-umi.principal_id
}

# Fivetran VM permissions for ADF UMI
resource "azurerm_role_assignment" "adf-to-fr-vms" {
  scope                = data.azurerm_resource_group.fr-rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# Selfhosted VM permissions for ADF UMI
resource "azurerm_role_assignment" "adf-to-shir-vms" {
  scope                = data.azurerm_resource_group.shir-rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# PBI Gateway VM permissions for ADF UMI
resource "azurerm_role_assignment" "adf-to-pbi-vms" {
  scope                = data.azurerm_resource_group.pbi-rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azurerm_user_assigned_identity.adf-umi.principal_id
}

# Management databricks connector User Managed Identity Storage Blob Data Contributor on Artifactory
resource "azurerm_role_assignment" "man-db-to-artifactory" {
  scope                = data.azurerm_resource_group.artifactory-rg.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_user_assigned_identity.man-dbw-conn-umi.principal_id
}
#------------------------------------------------------------------------------------------------
# Resource groups
# Managemtnt
data "azurerm_resource_group" "management-rg" {
  name      = "cdmz-management-rg"
}

#CDMZ Identity
# Management databricks connector User Managed Identity
data "azurerm_user_assigned_identity" "man-dbw-conn-umi" {
  name                = "cdmz-management-acdb-umi"
  resource_group_name = data.azurerm_resource_group.management-rg.name
}

#------------------------------------------------------------------------------------------------
# Permissions
# Management databricks connector User Managed Identity Storage Blob Data Contributor on metastore storage
resource "azurerm_role_assignment" "man-db-to-meta" {
  scope                = data.azurerm_resource_group.management-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_user_assigned_identity.man-dbw-conn-umi.principal_id
}
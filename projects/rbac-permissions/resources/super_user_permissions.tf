#------------------------------------------------------------------------------------------------
#SuperUser permissions
resource "azurerm_role_assignment" "super-user-to-cmdz" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-dev" {
  provider             = azurerm.dev
  scope                = data.azurerm_subscription.dev_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.dev_cdpz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-uat" {
  provider             = azurerm.uat
  scope                = data.azurerm_subscription.uat_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.uat_cdpz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-prod" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.super_user_aad_group.id

  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

#Management SPN permissions
resource "azurerm_role_assignment" "mngmnt-spn-to-dev" {
  provider             = azurerm.dev
  scope                = data.azurerm_subscription.dev_cdpz_sub.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.management_spn.id

  depends_on = [ data.azurerm_subscription.dev_cdpz_sub ]
}

resource "azurerm_role_assignment" "mngmnt-spn-to-uat" {
  provider             = azurerm.uat
  scope                = data.azurerm_subscription.uat_cdpz_sub.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.management_spn.id

  depends_on = [ data.azurerm_subscription.uat_cdpz_sub ]
}

resource "azurerm_role_assignment" "mngmnt-spn-to-prod" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.management_spn.id

  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

resource "azurerm_role_assignment" "mngmnt-spn-to-mngmnt" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_resource_group.artifactory-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.management_spn.id

  depends_on = [data.azurerm_resource_group.artifactory-rg ]
}

#Old subcription SPN permissions //to be deleted
resource "azurerm_role_assignment" "old-spn-to-prod" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.old_subscription_spn.id

  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

# VMs 
resource "azurerm_role_assignment" "super-user-vm-contr-cmdz" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

# VMs 
resource "azurerm_role_assignment" "em-vm-contr-cmdz" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = "3ba94197-51a7-4ee2-a2bf-6fd4badf0ded"

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

resource "azurerm_role_assignment" "em-vm-blob-contr" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_resource_group.ci-cd-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = "3ba94197-51a7-4ee2-a2bf-6fd4badf0ded"

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

# ADF
resource "azurerm_role_assignment" "super-user-to-dev-orch-and-ingest" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-orch-and-ingest-rg ]
}

resource "azurerm_role_assignment" "super-user-to-uat-orch-and-ingest" {
  provider             = azurerm.uat
  scope                = data.azurerm_resource_group.uat-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.uat-orch-and-ingest-rg ]
}

resource "azurerm_role_assignment" "super-user-to-prod-orch-and-ingest" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-orch-and-ingest-rg ]
}

# Storages
# Data Storage
resource "azurerm_role_assignment" "super-user-to-dev-data-storage" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-storage-rg ]
}

resource "azurerm_role_assignment" "super-user-to-uat-data-storage" {
  provider             = azurerm.uat
  scope                = data.azurerm_resource_group.uat-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.uat-storage-rg ]
}

resource "azurerm_role_assignment" "super-user-to-prod-data-storage" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-storage-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-storage-rg ]
}

# Landing
resource "azurerm_role_assignment" "super-user-to-dev-landing" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-landing-rg ]
}

resource "azurerm_role_assignment" "super-user-to-uat-landing" {
  provider             = azurerm.uat
  scope                = data.azurerm_resource_group.uat-landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.uat-landing-rg ]
}

resource "azurerm_role_assignment" "super-user-to-prod-landing" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-landing-rg.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-landing-rg ]
}

## Key vault for ochestration
resource "azurerm_role_assignment" "super-user-to-cmdz-kv" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-dev-kv" {
  provider             = azurerm.dev
  scope                = data.azurerm_subscription.dev_cdpz_sub.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.dev_cdpz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-uat-kv" {
  provider             = azurerm.uat
  scope                = data.azurerm_subscription.uat_cdpz_sub.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.super_user_aad_group.id

  depends_on = [ data.azurerm_subscription.uat_cdpz_sub ]
}

resource "azurerm_role_assignment" "super-user-to-prod-kv" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = var.super_user_aad_group.id

  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

resource "azurerm_synapse_role_assignment" "super-user-to-dev-synapse" {
  provider              = azurerm.dev
  synapse_workspace_id  = data.azurerm_synapse_workspace.dev_synapse_ws.id
  principal_id          = var.super_user_aad_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.dev_synapse_ws ]
}

resource "azurerm_synapse_role_assignment" "super-user-to-uat-synapse" {
  provider              = azurerm.uat
  synapse_workspace_id  = data.azurerm_synapse_workspace.uat_synapse_ws.id
  principal_id          = var.super_user_aad_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.uat_synapse_ws ]
}

resource "azurerm_synapse_role_assignment" "super-user-to-prod-synapse" {
  provider              = azurerm.prod
  synapse_workspace_id  = data.azurerm_synapse_workspace.prod_synapse_ws.id
  principal_id          = var.super_user_aad_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.prod_synapse_ws ]
}

resource "azurerm_synapse_workspace_sql_aad_admin" "super-user-as-dev-synapse-aad-admin" {
  provider              = azurerm.dev
  synapse_workspace_id  = data.azurerm_synapse_workspace.dev_synapse_ws.id
  login                 = var.super_user_aad_group.name
  object_id             = var.super_user_aad_group.id
  tenant_id             = var.tenant_id

  depends_on = [ data.azurerm_synapse_workspace.dev_synapse_ws ]
}

resource "azurerm_synapse_workspace_sql_aad_admin" "super-user-as-uat-synapse-aad-admin" {
  provider              = azurerm.uat
  synapse_workspace_id  = data.azurerm_synapse_workspace.uat_synapse_ws.id
  login                 = var.super_user_aad_group.name
  object_id             = var.super_user_aad_group.id
  tenant_id             = var.tenant_id

  depends_on = [ data.azurerm_synapse_workspace.uat_synapse_ws ]
}

resource "azurerm_synapse_workspace_sql_aad_admin" "super-user-as-prod-synapse-aad-admin" {
  provider              = azurerm.prod
  synapse_workspace_id  = data.azurerm_synapse_workspace.prod_synapse_ws.id
  login                 = var.super_user_aad_group.name
  object_id             = var.super_user_aad_group.id
  tenant_id             = var.tenant_id

  depends_on = [ data.azurerm_synapse_workspace.prod_synapse_ws ]
}
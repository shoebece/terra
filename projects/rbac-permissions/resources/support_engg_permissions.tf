#------------------------------------------------------------------------------------------------
# Permissions

#------------------------------------------------------------------------------------------------
# SupportEngg permissions
# On DEV env
resource "azurerm_role_assignment" "support-eng-to-dev-processing" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-processing-rg.id
  role_definition_name = "Reader"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-processing-rg ]
}

resource "azurerm_role_assignment" "support-eng-to-dev-sharing" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-sharing.id
  role_definition_name = "Reader"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-sharing ]
}

resource "azurerm_role_assignment" "support-eng-to-dev-orch-and-ingest" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [data.azurerm_resource_group.dev-orch-and-ingest-rg  ]
}

resource "azurerm_synapse_role_assignment" "support-eng-to-dev-synapse" {
  provider              = azurerm.dev
  synapse_workspace_id  = data.azurerm_synapse_workspace.dev_synapse_ws.id
  principal_id          = var.support_engg_aad_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.dev_synapse_ws ]
}

# On UAT env
# resource "azurerm_role_assignment" "support-eng-to-uat-processing" {
#   provider             = azurerm.uat
#   scope                = data.azurerm_resource_group.uat-processing-rg.id
#   role_definition_name = "Reader"
#   principal_id         = var.support_engg_aad_group.id

#   depends_on = [ data.azurerm_resource_group.uat-processing-rg ]
# }

# resource "azurerm_role_assignment" "support-eng-to-uat-sharing" {
#   provider             = azurerm.uat
#   scope                = data.azurerm_resource_group.uat-sharing.id
#   role_definition_name = "Reader"
#   principal_id         = var.support_engg_aad_group.id

#   depends_on = [ data.azurerm_resource_group.uat-sharing ]
# }

resource "azurerm_role_assignment" "support-eng-to-uat-orch-and-ingest" {
  provider             = azurerm.uat
  scope                = data.azurerm_resource_group.uat-orch-and-ingest-rg.id
  role_definition_name = "Reader"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.uat-orch-and-ingest-rg ]
}

# On PROD env
resource "azurerm_role_assignment" "support-eng-to-prod-orch-and-ingest" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-orch-and-ingest-rg.id
  role_definition_name = "Reader"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-orch-and-ingest-rg ]
}

resource "azurerm_role_assignment" "support-eng-to-prod-sharing" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-sharing.id
  role_definition_name = "Reader"
  principal_id         = var.support_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-sharing ]
}

## Synapse SQL Contributor to cdp_synapse_admin group.

resource "azurerm_synapse_role_assignment" "synapse-admins-to-prod-sharing" {
  provider              = azurerm.prod
  synapse_workspace_id  = data.azurerm_synapse_workspace.prod_synapse_ws.id
  principal_id          = var.cdp_synapse_admin_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.prod_synapse_ws ]
}

## Support Request contributor to cdp_suppengg

resource "azurerm_role_assignment" "supportrequest-to-cdp-mgmt-subscription" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub
  role_definition_name = "Support Request Contributor"
  principal_id         = var.support_engg_aad_group.id
}

resource "azurerm_role_assignment" "supportrequest-to-cdp-dev-subscription" {
  provider             = azurerm.dev
  scope                = data.azurerm_subscription.dev_cdpz_sub
  role_definition_name = "Support Request Contributor"
  principal_id         = var.support_engg_aad_group.id
}

resource "azurerm_role_assignment" "supportrequest-to-cdp-uat-subscription" {
  provider             = azurerm.uat
  scope                = data.azurerm_subscription.uat_cdpz_sub
  role_definition_name = "Support Request Contributor"
  principal_id         = var.support_engg_aad_group.id
}

resource "azurerm_role_assignment" "supportrequest-to-cdp-prod-subscription" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub
  role_definition_name = "Support Request Contributor"
  principal_id         = var.support_engg_aad_group.id
}
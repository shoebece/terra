#------------------------------------------------------------------------------------------------
# Permissions

#------------------------------------------------------------------------------------------------
# DataEngg permissions
# On DEV env
resource "azurerm_role_assignment" "data-eng-to-dev-processing" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-processing-rg.id
  role_definition_name = "Reader"
  principal_id         = var.data_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-processing-rg ]
}

resource "azurerm_role_assignment" "data-eng-to-dev-sharing" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-sharing.id
  role_definition_name = "Reader"
  principal_id         = var.data_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.dev-sharing ]
}

resource "azurerm_role_assignment" "data-eng-to-dev-orch-and-ingest" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.data_engg_aad_group.id

  depends_on = [data.azurerm_resource_group.dev-orch-and-ingest-rg  ]
}

resource "azurerm_synapse_role_assignment" "data-eng-to-dev-synapse" {
  provider              = azurerm.dev
  synapse_workspace_id  = data.azurerm_synapse_workspace.dev_synapse_ws.id
  principal_id          = var.data_engg_aad_group.id
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.dev_synapse_ws ]
}

resource "azurerm_synapse_role_assignment" "elitmind-to-dev-synapse" {
  provider              = azurerm.dev
  synapse_workspace_id  = data.azurerm_synapse_workspace.dev_synapse_ws.id
  principal_id          = "3ba94197-51a7-4ee2-a2bf-6fd4badf0ded"
  role_name             = "Synapse SQL Administrator"

  depends_on = [ data.azurerm_synapse_workspace.dev_synapse_ws ]
}

# On UAT env
# resource "azurerm_role_assignment" "data-eng-to-uat-processing" {
#   provider             = azurerm.uat
#   scope                = data.azurerm_resource_group.uat-processing-rg.id
#   role_definition_name = "Reader"
#   principal_id         = var.data_engg_aad_group.id

#   depends_on = [ data.azurerm_resource_group.uat-processing-rg ]
# }

# resource "azurerm_role_assignment" "data-eng-to-uat-sharing" {
#   provider             = azurerm.uat
#   scope                = data.azurerm_resource_group.uat-sharing.id
#   role_definition_name = "Reader"
#   principal_id         = var.data_engg_aad_group.id

#   depends_on = [ data.azurerm_resource_group.uat-sharing ]
# }

resource "azurerm_role_assignment" "data-eng-to-uat-orch-and-ingest" {
  provider             = azurerm.uat
  scope                = data.azurerm_resource_group.uat-orch-and-ingest-rg.id
  role_definition_name = "Reader"
  principal_id         = var.data_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.uat-orch-and-ingest-rg ]
}

# On PROD env
resource "azurerm_role_assignment" "data-eng-to-prod-orch-and-ingest" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-orch-and-ingest-rg.id
  role_definition_name = "Reader"
  principal_id         = var.data_engg_aad_group.id

  depends_on = [ data.azurerm_resource_group.prod-orch-and-ingest-rg ]
}
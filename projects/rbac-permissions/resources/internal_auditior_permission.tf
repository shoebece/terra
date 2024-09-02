#------------------------------------------------------------------------------------------------
#Internal Auditor permissions
resource "azurerm_role_assignment" "internal-auditor-user-to-cmdz" {
  provider             = azurerm.cdmz
  scope                = data.azurerm_subscription.cmdz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.cdpz_internal_audit_team_group.id

  depends_on = [ data.azurerm_subscription.cmdz_sub ]
}

resource "azurerm_role_assignment" "internal-auditor-user-to-dev" {
  provider             = azurerm.dev
  scope                = data.azurerm_subscription.dev_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.cdpz_internal_audit_team_group.id

  depends_on = [ data.azurerm_subscription.dev_cdpz_sub ]
}

resource "azurerm_role_assignment" "internal-auditor-user-to-uat" {
  provider             = azurerm.uat
  scope                = data.azurerm_subscription.uat_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.cdpz_internal_audit_team_group.id

  depends_on = [ data.azurerm_subscription.uat_cdpz_sub ]
}

resource "azurerm_role_assignment" "internal-auditor-user-to-prod" {
  provider             = azurerm.prod
  scope                = data.azurerm_subscription.prod_cdpz_sub.id
  role_definition_name = "Reader"
  principal_id         = var.cdpz_internal_audit_team_group.id

  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

######### Log Analytics Reader for prod ##########

resource "azurerm_role_assignment" "internal-auditor-user-to-prod-monitoring" {
  provider             = azurerm.prod
  scope                = data.azurerm_resource_group.prod-monitoring-rg.id
  role_definition_name = "Log Analytics Reader"
  principal_id         = var.cdpz_internal_audit_team_group.id
  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}

############### Data Factory Contributor for DEV ADF ###############

resource "azurerm_role_assignment" "internal-auditor-to-dev-adf" {
  provider             = azurerm.dev
  scope                = data.azurerm_resource_group.dev-orch-and-ingest-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = var.cdpz_internal_audit_team_group.id
  depends_on = [data.azurerm_subscription.prod_cdpz_sub ]
}


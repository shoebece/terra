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
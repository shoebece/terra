locals {
  resource_group_name          = join("-", ["cdpz", var.environment, "monitoring-rg"])
  log_analytics_workspace_name = join("-", ["cdpz", var.environment, "monitoring-log"])

  orch_and_ing_rg = join("-", ["cdpz", var.environment, "orchestration-and-ingestion-rg"])
  adf_name        = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf"])
  kv_orch_name    = join("-", ["cdpz", var.environment, "orchestr-kv"])

  landing_rg      = join("-", ["cdpz", var.environment, "landing-rg"])
  kv_landing_name = join("-", ["cdpz", var.environment, "landing-kv"])

  data_storage_rg      = join("-", ["cdpz", var.environment, "data-storage-rg"])
  kv_data_storage_name = join("-", ["cdpz", var.environment, "data-kv"])
  silver_stacc_name    = join("", ["cdpz", var.environment, "silver01dls"])
  internal_stacc_name  = join("", ["cdpz", var.environment, "internal02dls"])

  data_processing_rg       = join("-", ["cdpz", var.environment, "data-processing-rg"])
  kv_data_processing_name  = join("-", ["cdpz", var.environment, "proc-kv"])
  dbw_data_processing_name = join("-", ["cdpz", var.environment, "processing-dbw"])

  access_rg       = join("-", ["cdpz", var.environment, "access-rg"])
  kv_access_name  = join("-", ["cdpz", var.environment, "access-kv"])
  dbw_access_name = join("-", ["cdpz", var.environment, "access-dbw"])

  sharing_rg      = join("-", ["cdpz", var.environment, "sharing-rg"])
  syapse_ws_name  = join("-", ["cdpz", var.environment, "sharing-synapse"])
}

data "azurerm_resource_group" "monitoring-rg" {
  name = local.resource_group_name
}

data "azurerm_data_factory" "adf" {
  name                = local.adf_name
  resource_group_name = local.orch_and_ing_rg
}

data "azurerm_key_vault" "orch-kv" {
  name                = local.kv_orch_name
  resource_group_name = local.orch_and_ing_rg
}

data "azurerm_key_vault" "landing-kv" {
  name                = local.kv_landing_name
  resource_group_name = local.landing_rg
}

data "azurerm_key_vault" "data-kv" {
  name                = local.kv_data_storage_name
  resource_group_name = local.data_storage_rg
}

data "azurerm_storage_account" "silver-stacc" {
  name                = local.silver_stacc_name
  resource_group_name = local.data_storage_rg
}

data "azurerm_storage_account" "internal-stacc" {
  name                = local.internal_stacc_name
  resource_group_name = local.data_storage_rg
}

data "azurerm_key_vault" "proc-kv" {
  name                = local.kv_data_processing_name
  resource_group_name = local.data_processing_rg
}

data "azurerm_key_vault" "access-kv" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = local.kv_access_name
  resource_group_name = local.access_rg
}

data "azurerm_databricks_workspace" "processing-dbws" {
  name                = local.dbw_data_processing_name
  resource_group_name = local.data_processing_rg
}

data "azurerm_databricks_workspace" "access-dbws" {
  count               = (var.environment == "prod" ? 1 : 0)
  name                = local.dbw_access_name
  resource_group_name = local.access_rg
}

data "azurerm_synapse_workspace" "synapse_ws" {
  name                = local.syapse_ws_name
  resource_group_name = local.sharing_rg
}

resource "azurerm_log_analytics_workspace" "monitoring-log" {
  name                = local.log_analytics_workspace_name
  location            = var.resource_location
  resource_group_name = local.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge( var.resource_tags_common, var.resource_tags_spec )

  depends_on = [data.azurerm_resource_group.monitoring-rg]
}

resource "azurerm_monitor_diagnostic_setting" "adf-diag-set" {
  name                           = join("-", [var.environment, "adf", "diag-set"])
  target_resource_id             = data.azurerm_data_factory.adf.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "ActivityRuns"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "PipelineRuns"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "TriggerRuns"
    retention_policy {
      enabled = true
    }
  }

  depends_on = [data.azurerm_data_factory.adf]
}

resource "azurerm_monitor_diagnostic_setting" "orch-kv-diag-set" {
  name                           = join("-", [local.kv_orch_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.orch-kv.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    retention_policy {
      enabled = true
    }
  }

  depends_on = [data.azurerm_key_vault.orch-kv]
}

resource "azurerm_monitor_diagnostic_setting" "land-kv-diag-set" {
  name                           = join("-", [local.kv_landing_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.landing-kv.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    retention_policy {
      enabled = true
    }
  }

  depends_on = [data.azurerm_key_vault.landing-kv]
}

resource "azurerm_monitor_diagnostic_setting" "data-kv-diag-set" {
  name                           = join("-", [local.kv_data_storage_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.data-kv.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    retention_policy {
      enabled = true
    }
  }

  depends_on = [data.azurerm_key_vault.data-kv]
}

resource "azurerm_monitor_diagnostic_setting" "proc-kv-diag-set" {
  name                           = join("-", [local.kv_data_processing_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.proc-kv.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    retention_policy {
      enabled = true
    }
  }

  depends_on = [data.azurerm_key_vault.proc-kv]
}

resource "azurerm_monitor_diagnostic_setting" "access-kv-diag-set" {
  count                          = (var.environment == "prod" ? 1 : 0)
  name                           = join("-", [local.kv_access_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.access-kv[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "AuditEvent"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
    retention_policy {
      enabled = true
    }
  }
  depends_on = [data.azurerm_key_vault.access-kv]
}


resource "azurerm_monitor_diagnostic_setting" "processing-dbw-diag-set" {
  name                           = join("-", [local.dbw_data_processing_name, "diag-set"])
  target_resource_id             = data.azurerm_databricks_workspace.processing-dbws.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "dbfs"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "clusters"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "accounts"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "jobs"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "notebook"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "ssh"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "workspace"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "secrets"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "sqlPermissions"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "instancePools"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "sqlanalytics"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "genie"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "globalInitScripts"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "iamRole"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "databrickssql"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "deltaPipelines"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "repos"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "unityCatalog"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "clusterLibraries"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "webTerminal"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "gitCredentials"
    retention_policy {
      enabled = true
    }
  }
  depends_on = [data.azurerm_databricks_workspace.processing-dbws]
}

resource "azurerm_monitor_diagnostic_setting" "access-dbw-diag-set" {
  count                          = (var.environment == "prod" ? 1 : 0)
  name                           = join("-", [local.dbw_access_name, "diag-set"])
  target_resource_id             = data.azurerm_databricks_workspace.access-dbws[0].id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "dbfs"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "clusters"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "accounts"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "jobs"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "notebook"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "ssh"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "workspace"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "secrets"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "sqlPermissions"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "instancePools"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "sqlanalytics"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "genie"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "globalInitScripts"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "iamRole"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "databrickssql"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "deltaPipelines"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "repos"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "unityCatalog"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "clusterLibraries"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "webTerminal"
    retention_policy {
      enabled = true
    }
  }

  enabled_log {
    category = "gitCredentials"
    retention_policy {
      enabled = true
    }
  }
  depends_on = [data.azurerm_databricks_workspace.access-dbws]
}

resource "azurerm_monitor_diagnostic_setting" "synapse-ws-diag-set" {
  name                           = join("-", [local.syapse_ws_name, "diag-set"])
  target_resource_id             = data.azurerm_synapse_workspace.synapse_ws.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type = "Dedicated"

  enabled_log {
    category = "BuiltinSqlReqsEnded"
    retention_policy {
      enabled = true
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "silver-stacc-log" {
  count                           = (var.environment == "prod" ? 1 : 0)
  name                            = join("-", [local.silver_stacc_name, "diag-set"])
  target_resource_id              = "${data.azurerm_storage_account.silver-stacc.id}/blobServices/default/"
  log_analytics_workspace_id      = azurerm_log_analytics_workspace.monitoring-log.id
  log_analytics_destination_type  = "Dedicated"

  log {
    category = "StorageRead"
    enabled  = true
    retention_policy {
      days    = 0
      enabled = false
    }
  }
  metric {
    category = "Transaction"
    enabled  = false
    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

resource "azurerm_log_analytics_data_export_rule" "export_silver_stacc_log" {
  count                   = (var.environment == "prod" ? 1 : 0)
  name                    = "exportSilverStaccLogs"
  resource_group_name     = local.resource_group_name
  workspace_resource_id   = azurerm_log_analytics_workspace.monitoring-log.id
  destination_resource_id = data.azurerm_storage_account.internal-stacc.id
  table_names             = ["StorageBlobLogs"]
  enabled                 = true
}
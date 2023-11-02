data "azurerm_resource_group" "monitoring-rg" {
  name = var.resource_group_name
}

data "azurerm_data_factory" "shared-shir-adf" {
  name                = var.shared_shir_adf_name
  resource_group_name = var.shared_shir_adf_rg
}

data "azurerm_key_vault" "management-kv" {
  name                = var.management_kv_name
  resource_group_name = var.management_kv_rg
}

data "azurerm_databricks_workspace" "management-dbws" {
  name                = var.management_dbw_name
  resource_group_name = var.management_dbw_rg
}

resource "azurerm_log_analytics_workspace" "monitoring-log" {
  name                = "cdmz-monitoring-log"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = merge( var.resource_tags_common, var.resource_tags_spec ) 
  #internet_ingestion_enabled = 
  #internet_query_enabled = 

  depends_on = [data.azurerm_resource_group.monitoring-rg]
}

resource "azurerm_monitor_diagnostic_setting" "shared-shir-adf-diag-set" {
  name                           = join("-", [var.shared_shir_adf_name, "diag-set"])
  target_resource_id             = data.azurerm_data_factory.shared-shir-adf.id
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

}

resource "azurerm_monitor_diagnostic_setting" "management-kv-diag-set" {
  name                           = join("-", [var.management_kv_name, "diag-set"])
  target_resource_id             = data.azurerm_key_vault.management-kv.id
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

}

resource "azurerm_monitor_diagnostic_setting" "management-dbw-diag-set" {
  name                           = join("-", [var.management_dbw_name, "diag-set"])
  target_resource_id             = data.azurerm_databricks_workspace.management-dbws.id
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

}

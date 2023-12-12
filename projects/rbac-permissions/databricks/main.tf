locals {
  landing_ext_loc_falttend = flatten([
    for stacc in var.landing_ext_loc : [
        for cont in stacc.stconts : {
          key     = join("-", [stacc.name, cont])
          stacc   = stacc.name
          cont    = cont
        }
    ]
  ])
  data_ext_loc_falttend = flatten([
    for stacc in var.catalog_config : [
        for cont in stacc.stconts : {
          key     = join("-", [stacc.name, cont])
          stacc   = stacc.name
          type    = stacc.type
          cont    = cont
        }
    ]
  ])
  logistics_amr_ext_loc_falttend = flatten([
    for cont in var.logistics_amr_ext_loc.stconts : {
          key     = join("-", [var.logistics_amr_ext_loc.name, cont])
          stacc   = var.logistics_amr_ext_loc.name
          type    = var.logistics_amr_ext_loc.type
          cont    = cont
        }
  ])
  logistics_eur_ext_loc_falttend = flatten([
    for cont in var.logistics_eur_ext_loc.stconts : {
          key     = join("-", [var.logistics_eur_ext_loc.name, cont])
          stacc   = var.logistics_eur_ext_loc.name
          type    = var.logistics_eur_ext_loc.type
          cont    = cont
        }
  ])
}

#---------------------------------------------
# DEV
# Data engg
data "databricks_group" "data_engg" {
  provider      = databricks.devdbw
  display_name  = var.data_engg_aad_group.name
}

resource "databricks_permission_assignment" "add_data_engg" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_group.data_engg.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.data_engg ]
}

# Support engg
data "databricks_group" "support_engg" {
  provider      = databricks.devdbw
  display_name  = var.support_engg_aad_group.name
}

resource "databricks_permission_assignment" "add_support_engg" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_group.support_engg.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.support_engg ]
}

# BI engg
data "databricks_group" "ba_bi_eng" {
  provider      = databricks.devdbw
  display_name  = var.engg_aad_group.name
}

resource "databricks_permission_assignment" "add_ba_bi_eng" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_group.ba_bi_eng.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ba_bi_eng ]
}

# Super Users permissions
data "databricks_group" "super_users" {
  provider      = databricks.devdbw
  display_name  = var.super_user_aad_group.name
}

resource "databricks_permission_assignment" "add_super_users" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_group.super_users.id
  permissions   = ["ADMIN"]
}

# contract_logistics_amr
data "databricks_group" "contract_logistics_amr_bu" {
  provider      = databricks.globaldbw
  display_name  = var.contract_logistics_amr_bu.name
}

resource "databricks_permission_assignment" "add_contract_logistics_amr_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.contract_logistics_amr_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.contract_logistics_amr_bu ]
}

# contract_logistics_eur
data "databricks_group" "contract_logistics_eur_bu" {
  provider      = databricks.globaldbw
  display_name  = var.contract_logistics_eur_bu.name
}

resource "databricks_permission_assignment" "add_contract_logistics_eur_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.contract_logistics_eur_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.contract_logistics_eur_bu ]
}

## ----------------------------------------------------------
## Cluster
## DEV
data "databricks_cluster" "dev_interactive_cluster" {
  provider      = databricks.devdbw
  cluster_name  = "cdp-de-team-cluster"
}

resource "databricks_permissions" "cluster_usage" {
  provider          = databricks.devdbw
  cluster_id        = data.databricks_cluster.dev_interactive_cluster.id

  access_control {
    group_name       = data.databricks_group.data_engg.display_name
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    group_name       = data.databricks_group.data_engg.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.support_engg.display_name
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    group_name       = data.databricks_group.support_engg.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.super_users.display_name
    permission_level = "CAN_ATTACH_TO"
  }

  access_control {
    group_name       = data.databricks_group.super_users.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.dev_interactive_cluster,
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

## ----------------------------------------------------------
## Cluster
## Global
data "databricks_cluster" "global_synceur_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-synceur-team-cluster"
}

data "databricks_sql_warehouse" "global_synceur_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-synceur-team-warehouse"
}

resource "databricks_permissions" "global_clustersynceur_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_synceur_cluster.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_eur_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_synceur_cluster,
    data.databricks_group.contract_logistics_eur_bu
  ]
}

resource "databricks_permissions" "global_warehousesynceur_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_synceur_warehouse.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_eur_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_synceur_warehouse,
    data.databricks_group.contract_logistics_eur_bu
  ]
}

data "databricks_cluster" "global_syncamr_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-syncamr-team-cluster"
}

data "databricks_sql_warehouse" "global_syncamr_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-syncamr-team-warehouse"
}

resource "databricks_permissions" "global_clustersyncamr_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_syncamr_cluster.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_amr_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_syncamr_cluster,
    data.databricks_group.contract_logistics_amr_bu
  ]
}

resource "databricks_permissions" "global_warehousesyncamr_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_syncamr_warehouse.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_amr_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_syncamr_warehouse,
    data.databricks_group.contract_logistics_amr_bu
  ]
}

## ----------------------------------------------------------
## Data external locations
## DEV
resource "databricks_grants" "dev_data_ext_loc" {
  for_each = { for i, ext_loc in local.data_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", [each.value.type , "dev", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

resource "databricks_grants" "uat_data_ext_loc" {
  for_each = { for i, ext_loc in local.data_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", [each.value.type , "uat", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

resource "databricks_grants" "prod_data_ext_loc" {
  for_each = { for i, ext_loc in local.data_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", [each.value.type , "prod", each.value.stacc, each.value.cont, "ext-loc"])
  
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

## ----------------------------------------------------------
## Landing external locations
## DEV
resource "databricks_grants" "dev_landing_ext_loc" {
  for_each = { for i, ext_loc in local.landing_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", ["cdp-dev-landing", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}
## UAT
resource "databricks_grants" "uat_landing_ext_loc" {
  for_each = { for i, ext_loc in local.landing_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", ["cdp-uat-landing", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}
## PROD
resource "databricks_grants" "prod_landing_ext_loc" {
  for_each = { for i, ext_loc in local.landing_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.devdbw
  
  external_location = join("-", ["cdp-prod-landing", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = ["CREATE_EXTERNAL_TABLE", "READ_FILES", "WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

## ----------------------------------------------------------
## Logistics AMR external locations
## DEV
resource "databricks_grants" "dev_logistics_amr_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_amr_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "dev", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

resource "databricks_grants" "uat_logistics_amr_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_amr_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "uat", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

resource "databricks_grants" "prod_logistics_amr_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_amr_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "prod", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

## ----------------------------------------------------------
## Logistics EUR external locations
## DEV
resource "databricks_grants" "dev_logistics_eur_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_eur_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "dev", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

resource "databricks_grants" "uat_logistics_eur_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_eur_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "uat", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

resource "databricks_grants" "prod_logistics_eur_ext_loc" {
  for_each = { for i, ext_loc in local.logistics_eur_ext_loc_falttend: ext_loc.key => ext_loc }
  provider  = databricks.globaldbw
  
  external_location = join("-", [each.value.type , "prod", each.value.stacc, each.value.cont, "ext-loc"])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["WRITE_FILES"]
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

## ----------------------------------------------------------
## Catalogs
## DEV
resource "databricks_grants" "dev_dev_catalogs" {
  for_each = { for i, cat in var.catalog_config: cat.name => cat}
  provider  = databricks.devdbw

  catalog   = join("_", [each.value.type, "dev", each.value.name])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = var.catalog_writer_permission
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = var.catalog_writer_permission
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = var.catalog_writer_permission
  }

  grant {
    principal  = data.databricks_group.ba_bi_eng.display_name
    privileges = var.catalog_reader_permission
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

resource "databricks_grants" "dev_uat_catalogs" {
  for_each = { for i, cat in var.catalog_config: cat.name => cat}
  provider  = databricks.devdbw

  catalog   = join("_", [each.value.type, "uat", each.value.name])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = var.catalog_reader_permission
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = var.catalog_reader_permission
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = var.catalog_writer_permission
  }

  grant {
    principal  = data.databricks_group.ba_bi_eng.display_name
    privileges = var.catalog_reader_permission
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

resource "databricks_grants" "dev_prod_catalogs" {
  for_each = { for i, cat in var.catalog_config: cat.name => cat}
  provider  = databricks.devdbw

  catalog   = join("_", [each.value.type, "prod", each.value.name])
  grant {
    principal  = data.databricks_group.data_engg.display_name
    privileges = var.catalog_reader_permission
  }

  grant {
    principal  = data.databricks_group.support_engg.display_name
    privileges = var.catalog_reader_permission
  }

  grant {
    principal  = data.databricks_group.super_users.display_name
    privileges = var.catalog_writer_permission
  }

  grant {
    principal  = data.databricks_group.ba_bi_eng.display_name
    privileges = var.catalog_reader_permission
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

## ----------------------------------------------------------
## Catalogs Logistics AMR
## DEV
resource "databricks_grants" "dev_logisticsamr_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_amr_ext_loc.type, "dev", var.logistics_amr_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

resource "databricks_grants" "uat_logisticsamr_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_amr_ext_loc.type, "uat", var.logistics_amr_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

resource "databricks_grants" "prod_logisticsamr_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_amr_ext_loc.type, "prod", var.logistics_amr_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_amr_bu
  ]
}

## ----------------------------------------------------------
## Catalogs Logistics EUR
## DEV
resource "databricks_grants" "dev_logisticseur_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_eur_ext_loc.type, "dev", var.logistics_eur_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

resource "databricks_grants" "uat_logisticseur_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_eur_ext_loc.type, "uat", var.logistics_eur_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

resource "databricks_grants" "prod_logisticseur_catalogs" {
  provider  = databricks.globaldbw
  catalog   = join("_", [var.logistics_eur_ext_loc.type, "prod", var.logistics_eur_ext_loc.name])
  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = var.catalog_writer_permission
  }

  depends_on = [
    data.databricks_group.contract_logistics_eur_bu
  ]
}

# resource "databricks_grants" "dev_bi-engg-catalog" {
#   provider  = databricks.devdbw
  
#   catalog = "cdp_dev_silver"
  
#   grant {
#     principal  = data.databricks_group.data_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.support_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.super_users.display_name
#     privileges = ["ALL_PRIVILEGES"]
#   }

#   grant {
#     principal  = data.databricks_group.ba_bi_eng.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   depends_on = [
#     data.databricks_group.data_engg,
#     data.databricks_group.support_engg,
#     data.databricks_group.super_users,
#     data.databricks_group.ba_bi_eng
#   ]
# }

# ## UAT
# resource "databricks_grants" "uat_catalogs" {
#   for_each = { for i, cat in var.catalog_config: cat.name => cat}
#   provider  = databricks.devdbw

#   catalog   = join("_", [each.value.type, "uat", each.value.name])
#   grant {
#     principal  = data.databricks_group.data_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.support_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.super_users.display_name
#     privileges = ["ALL_PRIVILEGES"]
#   }

#   depends_on = [
#     data.databricks_group.data_engg,
#     data.databricks_group.support_engg,
#     data.databricks_group.super_users
#   ]
# }

# resource "databricks_grants" "uat_bi-engg-catalog" {
#   provider  = databricks.devdbw
  
#   catalog = "cdp_uat_silver"
#   grant {
#     principal  = data.databricks_group.data_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.support_engg.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   grant {
#     principal  = data.databricks_group.super_users.display_name
#     privileges = ["ALL_PRIVILEGES"]
#   }

#   grant {
#     principal  = data.databricks_group.ba_bi_eng.display_name
#     privileges = ["USE_CATALOG", "SELECT"]
#   }

#   depends_on = [
#     data.databricks_group.data_engg,
#     data.databricks_group.support_engg,
#     data.databricks_group.super_users,
#     data.databricks_group.ba_bi_eng
#   ]
# }

# ## PROD
# resource "databricks_grants" "prod_catalogs" {
#   for_each = { for i, cat in var.catalog_config: cat.name => cat}
#   provider  = databricks.devdbw

#   catalog   = join("_", [each.value.type, "prod", each.value.name])

#   grant {
#     principal  = data.databricks_group.super_users.display_name
#     privileges = ["ALL_PRIVILEGES"]
#   }

#   depends_on = [
#     data.databricks_group.super_users
#   ]
# }

# resource "databricks_permissions" "notebook_usage" {
#   notebook_path = var.etl_notebook_path

#   access_control {
#     group_name       = data.databricks_group.data_engg.display_name
#     permission_level = "CAN_MANAGE"
#   }

#       access_control {
#     group_name       = data.databricks_group.dasupport_enggta_engg.display_name
#     permission_level = "CAN_MANAGE"
#   }

#     depends_on = [
#       data.databricks_group.data_engg,
#       data.databricks_group.support_engg
#     ]
# }
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

# BI SPN
data "databricks_service_principal" "pbi_spn" {
  provider      = databricks.devdbw
  application_id = var.pbi_spn.app_id
}

resource "databricks_permission_assignment" "add_pbi_spn" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_service_principal.pbi_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.pbi_spn ]
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

  depends_on = [ data.databricks_group.super_users ]
}

resource "databricks_permission_assignment" "add_super_users_uat" {
  provider      = databricks.uatdbw
  principal_id  = data.databricks_group.super_users.id
  permissions   = ["ADMIN"]

  depends_on = [ data.databricks_group.super_users ]
}

resource "databricks_permission_assignment" "add_super_users_prod" {
  provider      = databricks.proddbw
  principal_id  = data.databricks_group.super_users.id
  permissions   = ["ADMIN"]

  depends_on = [ data.databricks_group.super_users ]
}

# ADF Dev UAMI
data "databricks_service_principal" "adf_dev_umi" {
  provider      = databricks.devdbw
  application_id = var.adf_dev_umi.app_id
}

resource "databricks_permission_assignment" "add_adf_dev_umi" {
  provider      = databricks.devdbw
  principal_id  = data.databricks_service_principal.adf_dev_umi.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.adf_dev_umi ]
}

# ADF UAT UAMI
data "databricks_service_principal" "adf_uat_umi" {
  provider      = databricks.uatdbw
  application_id  = var.adf_uat_umi.app_id
}

resource "databricks_permission_assignment" "add_adf_uat_umi" {
  provider      = databricks.uatdbw
  principal_id  = data.databricks_service_principal.adf_uat_umi.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.adf_uat_umi ]
}

# ADF Prod UAMI
data "databricks_service_principal" "adf_prod_umi" {
  provider      = databricks.proddbw
  application_id  = var.adf_prod_umi.app_id
}

resource "databricks_permission_assignment" "add_adf_prod_umi" {
  provider      = databricks.proddbw
  principal_id  = data.databricks_service_principal.adf_prod_umi.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.adf_prod_umi ]
}

## ----------------------------------------------------------
## Cluster
## DEV
data "databricks_cluster" "dev_interactive_cluster" {
  provider      = databricks.devdbw
  cluster_name  = "cdp-de-team-cluster"
}

resource "databricks_permissions" "dev_cluster_usage" {
  provider          = databricks.devdbw
  cluster_id        = data.databricks_cluster.dev_interactive_cluster.id

  access_control {
    group_name       = data.databricks_group.data_engg.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.support_engg.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.super_users.display_name
    permission_level = "CAN_MANAGE"
  }

  depends_on = [ 
    data.databricks_cluster.dev_interactive_cluster,
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users
  ]
}

## UAT
data "databricks_cluster" "uat_interactive_cluster" {
  provider      = databricks.uatdbw
  cluster_name  = "cdp-de-team-cluster"
}

resource "databricks_permissions" "uat_cluster_usage" {
  provider          = databricks.uatdbw
  cluster_id        = data.databricks_cluster.uat_interactive_cluster.id

  access_control {
    group_name       = data.databricks_group.super_users.display_name
    permission_level = "CAN_MANAGE"
  }

  depends_on = [ 
    data.databricks_cluster.uat_interactive_cluster,
    data.databricks_group.super_users
  ]
}

## PROD
data "databricks_cluster" "prod_interactive_cluster" {
  provider      = databricks.proddbw
  cluster_name  = "cdp-de-team-cluster"
}

resource "databricks_permissions" "prod_cluster_usage" {
  provider          = databricks.proddbw
  cluster_id        = data.databricks_cluster.prod_interactive_cluster.id

  access_control {
    group_name       = data.databricks_group.super_users.display_name
    permission_level = "CAN_MANAGE"
  }

  depends_on = [ 
    data.databricks_cluster.prod_interactive_cluster,
    data.databricks_group.super_users
  ]
}

# DEV ADF Cluster
data "databricks_cluster" "dev_adf_cluster" {
  provider      = databricks.devdbw
  cluster_name  = "cdp-adf-proc-cluster"
}

resource "databricks_permissions" "dev_adf_cluster_usage" {
  provider          = databricks.devdbw
  cluster_id        = data.databricks_cluster.dev_adf_cluster.id

  access_control {
    service_principal_name = data.databricks_service_principal.adf_dev_umi.application_id
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name = data.databricks_group.ba_bi_eng.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.pbi_spn.application_id
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.dev_adf_cluster,
    data.databricks_service_principal.adf_dev_umi,
    data.databricks_service_principal.pbi_spn,
    data.databricks_group.ba_bi_eng
  ]
}

# UAT ADF Cluster
data "databricks_cluster" "uat_adf_cluster" {
  provider      = databricks.uatdbw
  cluster_name  = "cdp-adf-proc-cluster"
}

resource "databricks_permissions" "uat_adf_cluster_usage" {
  provider          = databricks.uatdbw
  cluster_id        = data.databricks_cluster.uat_adf_cluster.id

  access_control {
    service_principal_name = data.databricks_service_principal.adf_uat_umi.application_id
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.uat_adf_cluster,
    data.databricks_service_principal.adf_uat_umi
  ]
}

# PROD ADF Cluster
data "databricks_cluster" "prod_adf_cluster" {
  provider      = databricks.proddbw
  cluster_name  = "cdp-adf-proc-cluster"
}

resource "databricks_permissions" "prod_adf_cluster_usage" {
  provider          = databricks.proddbw
  cluster_id        = data.databricks_cluster.prod_adf_cluster.id

  access_control {
    service_principal_name = data.databricks_service_principal.adf_prod_umi.application_id
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.prod_adf_cluster,
    data.databricks_service_principal.adf_prod_umi
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

# UAT
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

# PROD
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
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng
  ]
}

# UAT
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
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng
  ]
}

# PROD
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
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng
  ]
}



# # ------------------------------- GLOBAL ---------------------------------##
# # Adding user
resource "databricks_permission_assignment" "add_data_engg_global" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.data_engg.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.data_engg ]
}

# Support engg
resource "databricks_permission_assignment" "add_support_engg_global" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.support_engg.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.support_engg ]
}

# BI engg
resource "databricks_permission_assignment" "add_ba_bi_eng_global" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.ba_bi_eng.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ba_bi_eng ]
}

# Super Users permissions
resource "databricks_permission_assignment" "add_super_users_global" {
  provider      = databricks.globaldbw
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

resource "databricks_entitlements" "entitle_contract_logistics_amr" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.contract_logistics_amr_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.contract_logistics_amr_bu ]
}

# syncamr_spn
data "databricks_service_principal" "syncamr_spn" {
  provider      = databricks.globaldbw
  application_id  = var.syncamr_spn.app_id
}

resource "databricks_permission_assignment" "add_syncamr_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.syncamr_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.syncamr_spn ]
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

resource "databricks_entitlements" "entitle_contract_logistics_eur" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.contract_logistics_eur_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.contract_logistics_eur_bu ]
}

# synceur_spn
data "databricks_service_principal" "synceur_spn" {
  provider      = databricks.globaldbw
  application_id  = var.synceur_spn.app_id
}

resource "databricks_permission_assignment" "add_synceur_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.synceur_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.synceur_spn ]
}

# data_science
data "databricks_group" "data_science_bu" {
  provider      = databricks.globaldbw
  display_name  = var.data_science_bu.name
}

resource "databricks_permission_assignment" "add_data_science_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.data_science_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.data_science_bu ]
}

resource "databricks_entitlements" "entitle_data_science" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.data_science_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.data_science_bu ]
}

data "databricks_group" "data_science_bu_without_avd" {
  provider      = databricks.globaldbw
  display_name  = var.data_science_bu_without_avd.name
}

resource "databricks_permission_assignment" "add_data_science_bu_without_avd" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.data_science_bu_without_avd.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.data_science_bu_without_avd ]
}

resource "databricks_entitlements" "entitle_data_science_without_avd" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.data_science_bu_without_avd.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.data_science_bu_without_avd ]
}

# applied_science
data "databricks_group" "applied_science_bu" {
  provider      = databricks.globaldbw
  display_name  = var.applied_science_bu.name
}

resource "databricks_permission_assignment" "add_applied_science_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.applied_science_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.applied_science_bu ]
}

resource "databricks_entitlements" "entitle_applied_science" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.applied_science_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.applied_science_bu ]
}

# as_spn
data "databricks_service_principal" "as_spn" {
  provider      = databricks.globaldbw
  application_id  = var.as_spn.app_id
}

resource "databricks_permission_assignment" "add_as_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.as_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.as_spn ]
}

# crm_ho
# data "databricks_group" "crm_ho_bu" {
#   provider      = databricks.globaldbw
#   display_name  = var.crm_ho_bu.name
# }

# resource "databricks_permission_assignment" "add_crm_ho_bu" {
#   provider      = databricks.globaldbw
#   principal_id  = data.databricks_group.crm_ho_bu.id
#   permissions   = ["USER"]

#   depends_on = [ data.databricks_group.crm_ho_bu ]
# }

# resource "databricks_entitlements" "entitle_crm_ho" {
#   provider                   = databricks.globaldbw
#   group_id                   = data.databricks_group.crm_ho_bu.id
#   databricks_sql_access      = true
#   workspace_access           = true

#   depends_on = [ data.databricks_group.crm_ho_bu ]
# }

# crmho_spn
data "databricks_service_principal" "crmho_spn" {
  provider      = databricks.globaldbw
  application_id  = var.crmho_spn.app_id
}

resource "databricks_permission_assignment" "add_crmho_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.crmho_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.crmho_spn ]
}

# imperial_africa
data "databricks_group" "imperial_africa_bu" {
  provider      = databricks.globaldbw
  display_name  = var.imperial_africa_bu.name
}

resource "databricks_permission_assignment" "add_imperial_africa_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.imperial_africa_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.imperial_africa_bu ]
}

resource "databricks_entitlements" "entitle_imperial_africa" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.imperial_africa_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.imperial_africa_bu ]
}

# ila_spn
data "databricks_service_principal" "ila_spn" {
  provider      = databricks.globaldbw
  application_id  = var.ila_spn.app_id
}

resource "databricks_permission_assignment" "add_ila_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.ila_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.ila_spn ]
}

# imperial_intl
data "databricks_group" "imperial_intl_bu" {
  provider      = databricks.globaldbw
  display_name  = var.imperial_intl_bu.name
}

resource "databricks_permission_assignment" "add_imperial_intl_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.imperial_intl_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.imperial_intl_bu ]
}

resource "databricks_entitlements" "entitle_imperial_intl" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.imperial_intl_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.imperial_intl_bu ]
}

# ili_spn
data "databricks_service_principal" "ili_spn" {
  provider      = databricks.globaldbw
  application_id  = var.ili_spn.app_id
}

resource "databricks_permission_assignment" "add_ili_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.ili_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.ili_spn ]
}

# cdpz-pa-global
data "databricks_group" "pa_global_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pa_global_bu.name
}

resource "databricks_permission_assignment" "add_pa_global_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pa_global_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pa_global_bu ]
}

resource "databricks_entitlements" "entitle_pa_global_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pa_global_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pa_global_bu ]
}

# pa_spn
data "databricks_service_principal" "pa_spn" {
  provider      = databricks.globaldbw
  application_id  = var.pa_spn.app_id
}

resource "databricks_permission_assignment" "add_pa_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.pa_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.pa_spn ]
}

# cdpz-pa-ecomm
data "databricks_group" "pa_ecomm_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pa_ecomm_bu.name
}

resource "databricks_permission_assignment" "add_pa_ecomm_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pa_ecomm_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pa_ecomm_bu ]
}

resource "databricks_entitlements" "entitle_pa_ecomm_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pa_ecomm_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pa_ecomm_bu ]
}

# cdpz-pa-freight-forwarding
data "databricks_group" "pa_freight_forwarding_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pa_freight_forwarding_bu.name
}

resource "databricks_permission_assignment" "add_pa_freight_forwarding_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pa_freight_forwarding_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pa_freight_forwarding_bu ]
}

resource "databricks_entitlements" "entitle_pa_freight_forwarding_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pa_freight_forwarding_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pa_freight_forwarding_bu ]
}

# cdpz-pa-sco
data "databricks_group" "pa_sco_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pa_sco_bu.name
}

resource "databricks_permission_assignment" "add_pa_sco_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pa_sco_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pa_sco_bu ]
}

resource "databricks_entitlements" "entitle_pa_sco_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pa_sco_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pa_sco_bu ]
}

# cdpz-pa-searates
# data "databricks_group" "pa_searates_bu" {
#   provider      = databricks.globaldbw
#   display_name  = var.pa_searates_bu.name
# }

# resource "databricks_permission_assignment" "add_pa_searates_bu" {
#   provider      = databricks.globaldbw
#   principal_id  = data.databricks_group.pa_searates_bu.id
#   permissions   = ["USER"]

#   depends_on = [ data.databricks_group.pa_searates_bu ]
# }

# resource "databricks_entitlements" "entitle_pa_searates_bu" {
#   provider                   = databricks.globaldbw
#   group_id                   = data.databricks_group.pa_searates_bu.id
#   databricks_sql_access      = true
#   workspace_access           = true

#   depends_on = [ data.databricks_group.pa_searates_bu ]
# }

# cdpz-pa-trade-finance
data "databricks_group" "pa_trade_finance_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pa_trade_finance_bu.name
}

resource "databricks_permission_assignment" "add_pa_trade_finance_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pa_trade_finance_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pa_trade_finance_bu ]
}

resource "databricks_entitlements" "entitle_pa_trade_finance_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pa_trade_finance_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pa_trade_finance_bu ]
}

# cdpz-ext-users
data "databricks_group" "external_users_bu" {
  provider      = databricks.globaldbw
  display_name  = var.external_users_bu.name
}

resource "databricks_permission_assignment" "add_external_users_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.external_users_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.external_users_bu ]
}

resource "databricks_entitlements" "entitle_external_users_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.external_users_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.external_users_bu ]
}

# BA_ENG_MAXIMO
# data "databricks_group" "eng_maximo_bu" {
#   provider      = databricks.globaldbw
#   display_name  = var.eng_maximo_bu.name
# }

# resource "databricks_permission_assignment" "add_eng_maximo_bu" {
#   provider      = databricks.globaldbw
#   principal_id  = data.databricks_group.eng_maximo_bu.id
#   permissions   = ["USER"]

#   depends_on = [ data.databricks_group.eng_maximo_bu ]
# }

# resource "databricks_entitlements" "entitle_eng_maximo_bu" {
#   provider                   = databricks.globaldbw
#   group_id                   = data.databricks_group.eng_maximo_bu.id
#   databricks_sql_access      = true
#   workspace_access           = true

#   depends_on = [ data.databricks_group.eng_maximo_bu ]
# }

# cdpz-pa-pt
data "databricks_group" "grp_pa_pt" {
  provider      = databricks.globaldbw
  display_name  = var.pa_pt.name
}

resource "databricks_permission_assignment" "add_grp_pa_pt" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.grp_pa_pt.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.grp_pa_pt ]
}

resource "databricks_entitlements" "entitle_grp_pa_pt" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.grp_pa_pt.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.grp_pa_pt ]
}


# cdpz_apac_analytics
data "databricks_group" "apac_analytics_bu" {
  provider      = databricks.globaldbw
  display_name  = var.apac_analytics_bu.name
}

resource "databricks_permission_assignment" "add_apac_analytics_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.apac_analytics_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.apac_analytics_bu ]
}

resource "databricks_entitlements" "entitle_apac_analytics_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.apac_analytics_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.apac_analytics_bu ]
}

# BA_GHSE_HO
# data "databricks_group" "ghseho_bu" {
#   provider      = databricks.globaldbw
#   display_name  = var.ghseho_bu.name
# }

# resource "databricks_permission_assignment" "add_ghseho_bu" {
#   provider      = databricks.globaldbw
#   principal_id  = data.databricks_group.ghseho_bu.id
#   permissions   = ["USER"]

#   depends_on = [ data.databricks_group.ghseho_bu ]
# }

# resource "databricks_entitlements" "entitle_ghseho_bu" {
#   provider                   = databricks.globaldbw
#   group_id                   = data.databricks_group.ghseho_bu.id
#   databricks_sql_access      = true
#   workspace_access           = true

#   depends_on = [ data.databricks_group.ghseho_bu ]
# }

# BA_AuditTeam
# data "databricks_group" "audit_bu" {
#   provider      = databricks.globaldbw
#   display_name  = var.audit_bu.name
# }

# resource "databricks_permission_assignment" "add_audit_bu" {
#   provider      = databricks.globaldbw
#   principal_id  = data.databricks_group.audit_bu.id
#   permissions   = ["USER"]

#   depends_on = [ data.databricks_group.audit_bu ]
# }

# resource "databricks_entitlements" "entitle_audit_bu" {
#   provider                   = databricks.globaldbw
#   group_id                   = data.databricks_group.audit_bu.id
#   databricks_sql_access      = true
#   workspace_access           = true

#   depends_on = [ data.databricks_group.audit_bu ]
# }

# cdpz_ddw
data "databricks_group" "ddw_bu" {
  provider      = databricks.globaldbw
  display_name  = var.ddw_bu.name
}

resource "databricks_permission_assignment" "add_ddw_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.ddw_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ddw_bu ]
}

resource "databricks_entitlements" "entitle_ddw_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.ddw_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.ddw_bu ]
}

# cdpz_pt_sl_rocnd
data "databricks_group" "pt_sl_rocnd_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pt_rocnd_bu.name
}

resource "databricks_permission_assignment" "add_pt_sl_rocnd_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pt_sl_rocnd_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pt_sl_rocnd_bu ]
}

resource "databricks_entitlements" "entitle_pt_sl_rocnd_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pt_sl_rocnd_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pt_sl_rocnd_bu ]
}

# rocnd-spn
data "databricks_service_principal" "rocnd_spn" {
  provider      = databricks.globaldbw
  application_id  = var.pt_rocnd_spn.app_id
}

resource "databricks_permission_assignment" "add_rocnd_spn" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_service_principal.rocnd_spn.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_service_principal.rocnd_spn ]
}

# cdpz_pt_sl_cllqn
data "databricks_group" "pt_sl_cllqn_bu" {
  provider      = databricks.globaldbw
  display_name  = var.pt_cllqn_bu.name
}

resource "databricks_permission_assignment" "add_pt_sl_cllqn_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.pt_sl_cllqn_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.pt_sl_cllqn_bu ]
}

resource "databricks_entitlements" "entitle_pt_sl_cllqn_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.pt_sl_cllqn_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.pt_sl_cllqn_bu ]
}

# cdpz_ghse_amr
data "databricks_group" "ghse_amr_bu" {
  provider      = databricks.globaldbw
  display_name  = var.ghse_amr_bu.name
}

resource "databricks_permission_assignment" "add_ghse_amr_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.ghse_amr_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ghse_amr_bu ]
}

resource "databricks_entitlements" "entitle_ghse_amr_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.ghse_amr_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.ghse_amr_bu ]
}

# cdpz_ghse_sajed
data "databricks_group" "ghse_sajed_bu" {
  provider      = databricks.globaldbw
  display_name  = var.ghse_sajed_bu.name
}

resource "databricks_permission_assignment" "add_ghse_sajed_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.ghse_sajed_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ghse_sajed_bu ]
}

resource "databricks_entitlements" "entitle_ghse_sajed_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.ghse_sajed_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.ghse_sajed_bu ]
}

# cdpz_gblgp_crm
data "databricks_group" "gblgp_crm_bu" {
  provider      = databricks.globaldbw
  display_name  = var.gblgp_crm_bu.name
}

resource "databricks_permission_assignment" "add_gblgp_crm_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.gblgp_crm_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.gblgp_crm_bu ]
}

resource "databricks_entitlements" "entitle_gblgp_crm_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.gblgp_crm_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.gblgp_crm_bu ]
}

# cdpz_ghse_aejea
data "databricks_group" "ghse_aeja_bu" {
  provider      = databricks.globaldbw
  display_name  = var.ghse_aeja_bu.name
}

resource "databricks_permission_assignment" "add_ghse_aeja_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.ghse_aeja_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.ghse_aeja_bu ]
}

resource "databricks_entitlements" "entitle_ghse_aeja_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.ghse_aeja_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.ghse_aeja_bu ]
}

# cdpz_eur_freight_fwd
data "databricks_group" "eur_freightfwd_bu" {
  provider      = databricks.globaldbw
  display_name  = var.eur_freightfwd_bu.name
}

resource "databricks_permission_assignment" "add_eur_freightfwd_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.eur_freightfwd_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.eur_freightfwd_bu ]
}

resource "databricks_entitlements" "entitle_eur_freightfwd_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.eur_freightfwd_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.eur_freightfwd_bu ]
}

# cdpz_sco_product_team
data "databricks_group" "sco_prod_bu" {
  provider      = databricks.globaldbw
  display_name  = var.sco_prod_bu.name
}

resource "databricks_permission_assignment" "add_sco_prod_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.sco_prod_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.sco_prod_bu ]
}

resource "databricks_entitlements" "entitle_sco_prod_bu" {
  provider                   = databricks.globaldbw
  group_id                   = data.databricks_group.sco_prod_bu.id
  databricks_sql_access      = true
  workspace_access           = true

  depends_on = [ data.databricks_group.sco_prod_bu ]
}

## ----------------------------------------------------------
## Cluster Sync EUR
data "databricks_cluster" "global_synceur_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-synceur-team-cluster"
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

## PBI Cluster Sync EUR
data "databricks_cluster" "global_synceur_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-synceur-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclustersynceur_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_synceur_pbicluster.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_eur_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.synceur_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_synceur_pbicluster,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_service_principal.synceur_spn
  ]
}

# # SQL Waerhouse Sync EUR
# data "databricks_sql_warehouse" "global_synceur_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-synceur-team-warehouse"
# }

# resource "databricks_permissions" "global_warehousesynceur_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_synceur_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.contract_logistics_eur_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_synceur_warehouse,
#     data.databricks_group.contract_logistics_eur_bu
#   ]
# }

# Cluster Sync AMR
data "databricks_cluster" "global_syncamr_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-syncamr-team-cluster"
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

data "databricks_cluster" "global_syncamr_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-syncamr-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclustersyncamr_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_syncamr_pbicluster.id

  access_control {
    group_name       = data.databricks_group.contract_logistics_amr_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.syncamr_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_syncamr_pbicluster,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_service_principal.syncamr_spn
  ]
}

# Cluster Maximo
data "databricks_cluster" "global_maximo_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-maximo-team-cluster"
}

# resource "databricks_permissions" "global_clustermaximo_usage" {
#   provider          = databricks.globaldbw
#   cluster_id        = data.databricks_cluster.global_maximo_cluster.id

#   access_control {
#     group_name       = data.databricks_group.eng_maximo_bu.display_name
#     permission_level = "CAN_RESTART"
#   }

#   depends_on = [ 
#     data.databricks_cluster.global_maximo_cluster,
#     data.databricks_group.eng_maximo_bu
#   ]
# }


# Cluster PA SQL Warehouse PBI Cluster
data "databricks_sql_warehouse" "global_pa_sqlwarehouse_cluster" {
  provider      = databricks.globaldbw
  name  = "cdp-pa-pbi-warehouse"
}

resource "databricks_permissions" "global_cluster_pa_sqlwarehouse_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_sql_warehouse.global_pa_sqlwarehouse_cluster.id

  access_control {
    group_name       = data.databricks_group.grp_pa_pt.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_pa_sqlwarehouse_cluster,
    data.databricks_group.grp_pa_pt
  ]
}

# Cluster APAC Analytics
data "databricks_cluster" "global_apac_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-apac-team-cluster"
}

resource "databricks_permissions" "global_apac_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_apac_cluster.id

  access_control {
    group_name       = data.databricks_group.apac_analytics_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_apac_cluster,
    data.databricks_group.apac_analytics_bu
  ]
}

# Cluster GHSE
data "databricks_cluster" "global_ghse_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ghse-team-cluster"
}

# resource "databricks_permissions" "global_ghse_usage" {
#   provider          = databricks.globaldbw
#   cluster_id        = data.databricks_cluster.global_ghse_cluster.id

#   access_control {
#     group_name       = data.databricks_group.ghseho_bu.display_name
#     permission_level = "CAN_RESTART"
#   }

#   depends_on = [ 
#     data.databricks_cluster.global_ghse_cluster,
#     data.databricks_group.ghseho_bu
#   ]
# }

# # Cluster Audit Team
# data "databricks_cluster" "global_audit_cluster" {
#   provider      = databricks.globaldbw
#   cluster_name  = "cdp-audit-team-cluster"
# }

# resource "databricks_permissions" "global_audit_usage" {
#   provider          = databricks.globaldbw
#   cluster_id        = data.databricks_cluster.global_audit_cluster.id

#   access_control {
#     group_name       = data.databricks_group.audit_bu.display_name
#     permission_level = "CAN_RESTART"
#   }

#   depends_on = [ 
#     data.databricks_cluster.global_audit_cluster,
#     data.databricks_group.audit_bu
#   ]
# }

# # SQL Warehouse Sync AMR
# data "databricks_sql_warehouse" "global_syncamr_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-syncamr-team-warehouse"
# }

# resource "databricks_permissions" "global_warehousesyncamr_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_syncamr_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.contract_logistics_amr_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_syncamr_warehouse,
#     data.databricks_group.contract_logistics_amr_bu
#   ]
# }

## Cluster PA
data "databricks_cluster" "global_pa_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-pa-team-cluster"
}

resource "databricks_permissions" "global_clusterpa_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_pa_cluster.id

  access_control {
    group_name       = data.databricks_group.pa_global_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_ecomm_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_freight_forwarding_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_sco_bu.display_name
    permission_level = "CAN_RESTART"
  }

  # access_control {
  #   group_name       = data.databricks_group.pa_searates_bu.display_name
  #   permission_level = "CAN_RESTART"
  # }

  access_control {
    group_name       = data.databricks_group.pa_trade_finance_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_pa_cluster,
    data.databricks_group.pa_global_bu,
    data.databricks_group.pa_ecomm_bu,
    data.databricks_group.pa_freight_forwarding_bu,
    data.databricks_group.pa_sco_bu,
    # data.databricks_group.pa_searates_bu,
    data.databricks_group.pa_trade_finance_bu
  ]
}

data "databricks_cluster" "global_pa_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-pa-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclusterpa_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_pa_pbicluster.id

  access_control {
    group_name       = data.databricks_group.pa_global_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_ecomm_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_freight_forwarding_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.pa_sco_bu.display_name
    permission_level = "CAN_RESTART"
  }

  # access_control {
  #   group_name       = data.databricks_group.pa_searates_bu.display_name
  #   permission_level = "CAN_RESTART"
  # }

  access_control {
    group_name       = data.databricks_group.pa_trade_finance_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.pa_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_pa_pbicluster,
    data.databricks_group.pa_global_bu,
    data.databricks_group.pa_ecomm_bu,
    data.databricks_group.pa_freight_forwarding_bu,
    data.databricks_group.pa_sco_bu,
    # data.databricks_group.pa_searates_bu,
    data.databricks_group.pa_trade_finance_bu,
    data.databricks_service_principal.pa_spn
  ]
}

# SQL Waerhouse PA
# data "databricks_sql_warehouse" "global_pa_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-pa-team-warehouse"
# }

# resource "databricks_permissions" "global_warehousepa_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_pa_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.product_analytics_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   access_control {
#     group_name       = data.databricks_group.product_analytics_confd_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_pa_warehouse,
#     data.databricks_group.product_analytics_bu,
#     data.databricks_group.product_analytics_confd_bu
#   ]
# }

# Cluster Data Science
data "databricks_cluster" "global_ds_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ds-team-cluster"
}

resource "databricks_permissions" "global_clusterds_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ds_cluster.id

  access_control {
    group_name       = data.databricks_group.data_science_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.data_science_bu_without_avd.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ds_cluster,
    data.databricks_group.data_science_bu,
    data.databricks_group.data_science_bu_without_avd
  ]
}

# Cluster Applied Science
data "databricks_cluster" "global_as_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-as-team-cluster"
}

resource "databricks_permissions" "global_clusteras_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_as_cluster.id

  access_control {
    group_name       = data.databricks_group.applied_science_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_as_cluster,
    data.databricks_group.applied_science_bu
  ]
}

data "databricks_cluster" "global_as_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-as-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclusteras_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_as_pbicluster.id

  access_control {
    group_name       = data.databricks_group.applied_science_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.as_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_as_pbicluster,
    data.databricks_group.applied_science_bu,
    data.databricks_service_principal.as_spn
  ]
}

# SQL Warehouse Applied Science
# data "databricks_sql_warehouse" "global_as_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-as-team-warehouse"
# }

# resource "databricks_permissions" "global_warehouseas_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_as_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.applied_science_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_as_warehouse,
#     data.databricks_group.applied_science_bu
#   ]
# }

# Cluster CRM HO
data "databricks_cluster" "global_crmho_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-crmho-team-cluster"
}

# resource "databricks_permissions" "global_clustercrmho_usage" {
#   provider          = databricks.globaldbw
#   cluster_id        = data.databricks_cluster.global_crmho_cluster.id

#   access_control {
#     group_name       = data.databricks_group.crm_ho_bu.display_name
#     permission_level = "CAN_RESTART"
#   }

#   depends_on = [ 
#     data.databricks_cluster.global_crmho_cluster,
#     data.databricks_group.crm_ho_bu
#   ]
# }

data "databricks_cluster" "global_crmho_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-crmho-pbi-cluster"
}

# resource "databricks_permissions" "global_pbiclustercrmho_usage" {
#   provider          = databricks.globaldbw
#   cluster_id        = data.databricks_cluster.global_crmho_pbicluster.id

#   access_control {
#     group_name       = data.databricks_group.crm_ho_bu.display_name
#     permission_level = "CAN_RESTART"
#   }

#   access_control {
#     service_principal_name = data.databricks_service_principal.crmho_spn.application_id
#     permission_level       = "CAN_RESTART"
#   }

#   depends_on = [ 
#     data.databricks_cluster.global_crmho_pbicluster,
#     data.databricks_group.crm_ho_bu,
#     data.databricks_service_principal.crmho_spn
#   ]
# }

# SQL Warehouse CRM HO
# data "databricks_sql_warehouse" "global_crmho_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-crmho-team-warehouse"
# }

# resource "databricks_permissions" "global_warehousecrmho_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_crmho_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.crm_ho_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_crmho_warehouse,
#     data.databricks_group.crm_ho_bu
#   ]
# }

# Cluster ILA
data "databricks_cluster" "global_ila_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ila-team-cluster"
}

resource "databricks_permissions" "global_clusterila_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ila_cluster.id

  access_control {
    group_name       = data.databricks_group.imperial_africa_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ila_cluster,
    data.databricks_group.imperial_africa_bu
  ]
}

data "databricks_cluster" "global_ila_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ila-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclusterila_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ila_pbicluster.id

  access_control {
    group_name       = data.databricks_group.imperial_africa_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.ila_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ila_pbicluster,
    data.databricks_group.imperial_africa_bu,
    data.databricks_service_principal.ila_spn
  ]
}

# SQL Warehouse ILA
# data "databricks_sql_warehouse" "global_ila_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-ila-team-warehouse"
# }

# resource "databricks_permissions" "global_warehouseila_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_ila_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.imperial_africa_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_ila_warehouse,
#     data.databricks_group.imperial_africa_bu
#   ]
# }

# Cluster ILI
data "databricks_cluster" "global_ili_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ili-team-cluster"
}

resource "databricks_permissions" "global_clusterili_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ili_cluster.id

  access_control {
    group_name       = data.databricks_group.imperial_intl_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ili_cluster,
    data.databricks_group.imperial_intl_bu
  ]
}

data "databricks_cluster" "global_ili_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ili-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclusterili_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ili_pbicluster.id

  access_control {
    group_name       = data.databricks_group.imperial_intl_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.ili_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ili_pbicluster,
    data.databricks_group.imperial_intl_bu,
    data.databricks_service_principal.ili_spn
  ]
}

# Cluster ROCND
data "databricks_cluster" "global_rocnd_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-rocnd-team-cluster"
}

resource "databricks_permissions" "global_clusterrocnd_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_rocnd_cluster.id

  access_control {
    group_name       = data.databricks_group.pt_sl_rocnd_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_rocnd_cluster,
    data.databricks_group.pt_sl_rocnd_bu
  ]
}

data "databricks_cluster" "global_rocnd_pbicluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-rocnd-pbi-cluster"
}

resource "databricks_permissions" "global_pbiclusterrocnd_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_rocnd_pbicluster.id

  access_control {
    group_name       = data.databricks_group.pt_sl_rocnd_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    service_principal_name = data.databricks_service_principal.rocnd_spn.application_id
    permission_level       = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_rocnd_pbicluster,
    data.databricks_group.pt_sl_rocnd_bu,
    data.databricks_service_principal.rocnd_spn
  ]
}

# Cluster DDW
data "databricks_cluster" "global_ddw_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ddw-team-cluster"
}

resource "databricks_permissions" "global_clusterddw_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_ddw_cluster.id

  access_control {
    group_name       = data.databricks_group.ddw_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_ddw_cluster,
    data.databricks_group.ddw_bu
  ]
}

data "databricks_sql_warehouse" "global_ddw_pbicluster" {
  provider      = databricks.globaldbw
  name  = "cdp-ddw-pbi-warehouse"
}

resource "databricks_permissions" "global_pbiclusterddw_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_sql_warehouse.global_ddw_pbicluster.id

  access_control {
    group_name       = data.databricks_group.ddw_bu.display_name
    permission_level = "CAN_RESTART"
  }

  # access_control {
  #   service_principal_name = data.databricks_service_principal.ddw_spn.application_id
  #   permission_level       = "CAN_RESTART"
  # }

  depends_on = [ 
    data.databricks_sql_warehouse.global_ddw_pbicluster,
    data.databricks_group.ddw_bu
    # ,data.databricks_service_principal.rocnd_spn
  ]
}

# SQL Warehouse ILI
# data "databricks_sql_warehouse" "global_ili_warehouse" {
#   provider      = databricks.globaldbw
#   name          = "cdp-ili-team-warehouse"
# }

# resource "databricks_permissions" "global_warehouseili_usage" {
#   provider          = databricks.globaldbw
#   sql_endpoint_id   = data.databricks_sql_warehouse.global_ili_warehouse.id

#   access_control {
#     group_name       = data.databricks_group.imperial_intl_bu.display_name
#     permission_level = "CAN_USE"
#   }

#   depends_on = [ 
#     data.databricks_sql_warehouse.global_ili_warehouse,
#     data.databricks_group.imperial_intl_bu
#   ]
# }

# Cluster External Users
data "databricks_cluster" "global_extusers_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-ext-team-cluster"
}

resource "databricks_permissions" "global_clusterext_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_extusers_cluster.id

  access_control {
    group_name       = data.databricks_group.external_users_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_extusers_cluster,
    data.databricks_group.external_users_bu
  ]
}

# SQL Warehouse - Adhoc Querying
data "databricks_sql_warehouse" "global_edashared_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-shared-eda-warehouse"
}

resource "databricks_permissions" "global_edashared_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_edashared_warehouse.id

  access_control {
    group_name       = data.databricks_group.ddw_bu.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.pt_sl_cllqn_bu.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.ghse_amr_bu.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.ghse_sajed_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.gblgp_crm_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.ghse_aeja_bu.display_name
    permission_level = "CAN_USE"
  }  
  
  access_control {
    group_name       = data.databricks_group.eur_freightfwd_bu.display_name
    permission_level = "CAN_USE"
  }  
  
  access_control {
    group_name       = data.databricks_group.sco_prod_bu.display_name
    permission_level = "CAN_USE"
  }  

  depends_on = [ 
    data.databricks_sql_warehouse.global_edashared_warehouse,
    data.databricks_group.ddw_bu,
    data.databricks_group.pt_sl_cllqn_bu,
    data.databricks_group.ghse_amr_bu,
    data.databricks_group.ghse_sajed_bu,
    data.databricks_group.gblgp_crm_bu,
    data.databricks_group.ghse_aeja_bu,
    data.databricks_group.eur_freightfwd_bu,
    data.databricks_group.sco_prod_bu
  ]
}

##------------------------------------------------------- PROD-ACCESS WORKSPACE --------------------------------------------------------##
# ADDING USERS
# cdpz_pt_amr
data "databricks_group" "bi_pt_amr_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_amr_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_amr_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_amr_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_amr_bu ]
}

# cdpz_pt_anz
data "databricks_group" "bi_pt_anz_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_anz_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_anz_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_anz_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_anz_bu ]
}

# cdpz_pt_apac
data "databricks_group" "bi_pt_apac_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_apac_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_apac_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_apac_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_apac_bu ]
}

# cdpz_pt_mea
data "databricks_group" "bi_pt_mea_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_mea_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_mea_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_mea_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_mea_bu ]
}

# cdpz_pt_menasco
data "databricks_group" "bi_pt_menasco_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_menasco_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_menasco_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_menasco_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_menasco_bu ]
}

# cdpz_pt_sco
data "databricks_group" "bi_pt_sco_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_sco_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_sco_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_sco_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_sco_bu ]
}

# cdpz_pt_ssa
data "databricks_group" "bi_pt_ssa_bu" {
  provider      = databricks.access
  display_name  = var.bi_pt_ssa_bu.name
}

resource "databricks_permission_assignment" "add_bi_pt_ssa_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_pt_ssa_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_pt_ssa_bu ]
}

# cdpz_gops_dashboard_users
data "databricks_group" "bi_gops_bu" {
  provider      = databricks.access
  display_name  = var.bi_gops_bu.name
}

resource "databricks_permission_assignment" "add_bi_gops_bu" {
  provider      = databricks.access
  principal_id  = data.databricks_group.bi_gops_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.bi_gops_bu ]
}


# Prod-Access - PBI reporting Warehouse
data "databricks_sql_warehouse" "access_rpt_warehouse" {
  provider      = databricks.access
  name          = "cdp-de-team-warehouse"
}

resource "databricks_permissions" "access_rpt_warehouse_usage" {
  provider          = databricks.access
  sql_endpoint_id   = data.databricks_sql_warehouse.access_rpt_warehouse.id

  access_control {
    service_principal_name = data.databricks_service_principal.pbi_spn.application_id
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.ba_bi_eng.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.bi_pt_amr_bu.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.bi_pt_anz_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_pt_apac_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_pt_mea_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_pt_menasco_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_pt_sco_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_pt_ssa_bu.display_name
    permission_level = "CAN_USE"
  }
  
  access_control {
    group_name       = data.databricks_group.bi_gops_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.access_rpt_warehouse,
    data.databricks_group.bi_pt_amr_bu,
    data.databricks_group.bi_pt_anz_bu,
    data.databricks_group.bi_pt_apac_bu,
    data.databricks_group.bi_pt_mea_bu,
    data.databricks_group.bi_pt_menasco_bu,
    data.databricks_group.bi_pt_sco_bu,
    data.databricks_group.bi_pt_ssa_bu,
    data.databricks_group.bi_gops_bu
  ]
}

## ----------------------------------------------------------
## Artifactory 
## Maven
resource "databricks_grants" "artifactory_ext_loc_maven" {
  provider  = databricks.devdbw
  external_location = "cdm-artifactory-maven-ext-loc"
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
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_global_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_ecomm_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_freight_forwarding_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_sco_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.pa_searates_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.pa_trade_finance_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.crm_ho_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.external_users_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu_without_avd.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.pa_global_bu,
    data.databricks_group.pa_ecomm_bu,
    data.databricks_group.pa_freight_forwarding_bu,
    data.databricks_group.pa_sco_bu,
    # data.databricks_group.pa_searates_bu,
    data.databricks_group.pa_trade_finance_bu,
    data.databricks_group.applied_science_bu,
    # data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu,
    data.databricks_group.external_users_bu,
    data.databricks_group.data_science_bu_without_avd,
    data.databricks_group.data_science_bu
  ]
}

## Pypi
resource "databricks_grants" "artifactory_ext_loc_pypi" {
  provider  = databricks.devdbw
  external_location = "cdm-artifactory-pypi-ext-loc"
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
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_global_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_ecomm_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_freight_forwarding_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_sco_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.pa_searates_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.pa_trade_finance_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.crm_ho_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.external_users_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu_without_avd.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.pa_global_bu,
    data.databricks_group.pa_ecomm_bu,
    data.databricks_group.pa_freight_forwarding_bu,
    data.databricks_group.pa_sco_bu,
    # data.databricks_group.pa_searates_bu,
    data.databricks_group.pa_trade_finance_bu,
    data.databricks_group.applied_science_bu,
    # data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu,
    data.databricks_group.external_users_bu,
    data.databricks_group.data_science_bu_without_avd,
    data.databricks_group.data_science_bu
  ]
}

## Scripts
resource "databricks_grants" "artifactory_ext_loc_scripts" {
  provider  = databricks.devdbw
  external_location = "cdm-artifactory-scripts-ext-loc"
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
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_global_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_ecomm_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_freight_forwarding_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.pa_sco_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.pa_searates_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.pa_trade_finance_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  # grant {
  #   principal  = data.databricks_group.crm_ho_bu.display_name
  #   privileges = ["READ_FILES"]
  # }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.external_users_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.data_science_bu_without_avd.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.pa_global_bu,
    data.databricks_group.pa_ecomm_bu,
    data.databricks_group.pa_freight_forwarding_bu,
    data.databricks_group.pa_sco_bu,
    # data.databricks_group.pa_searates_bu,
    data.databricks_group.pa_trade_finance_bu,
    data.databricks_group.applied_science_bu,
    # data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu,
    data.databricks_group.external_users_bu,
    data.databricks_group.data_science_bu_without_avd,
    data.databricks_group.data_science_bu
  ]
}

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
          loc_logistics_amr = stacc.loc_logistics_amr
          loc_logistics_eur = stacc.loc_logistics_eur
          cat_logistics_amr = stacc.cat_logistics_amr
          cat_logistics_eur = stacc.cat_logistics_eur
          loc_pa  = stacc.loc_pa
          cat_pa  = stacc.cat_pa
          loc_pa_confd  = stacc.loc_pa_confd
          cat_pa_confd  = stacc.cat_pa_confd
          loc_as  = stacc.loc_as
          cat_as  = stacc.cat_as
          loc_crmho  = stacc.loc_crmho
          cat_crmho  = stacc.cat_crmho
          loc_ila  = stacc.loc_ila
          cat_ila  = stacc.cat_ila
          loc_ili  = stacc.loc_ili
          cat_ili  = stacc.cat_ili
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.loc_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.loc_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.loc_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.loc_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.loc_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.loc_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.loc_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.loc_ili
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.loc_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.loc_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.loc_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.loc_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.loc_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.loc_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.loc_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.loc_ili
  }


  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.loc_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.loc_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.loc_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.loc_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.loc_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.loc_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.loc_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.loc_ili
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.cat_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.cat_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.cat_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.cat_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.cat_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.cat_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.cat_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.cat_ili
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.cat_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.cat_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.cat_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.cat_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.cat_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.cat_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.cat_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.cat_ili
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

  grant {
    principal  = data.databricks_group.contract_logistics_amr_bu.display_name
    privileges = each.value.cat_logistics_amr
  }

  grant {
    principal  = data.databricks_group.contract_logistics_eur_bu.display_name
    privileges = each.value.cat_logistics_eur
  }

  grant {
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = each.value.cat_pa
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = each.value.cat_pa_confd
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = each.value.cat_as
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = each.value.cat_crmho
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = each.value.cat_ila
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = each.value.cat_ili
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.ba_bi_eng,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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

# product_analytics
data "databricks_group" "product_analytics_bu" {
  provider      = databricks.globaldbw
  display_name  = var.product_analytics_bu.name
}

resource "databricks_permission_assignment" "add_product_analytics_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.product_analytics_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.product_analytics_bu ]
}

# product_analytics_confidential
data "databricks_group" "product_analytics_confd_bu" {
  provider      = databricks.globaldbw
  display_name  = var.product_analytics_confd_bu.name
}

resource "databricks_permission_assignment" "add_product_analytics_confd_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.product_analytics_confd_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.product_analytics_confd_bu ]
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

# crm_ho
data "databricks_group" "crm_ho_bu" {
  provider      = databricks.globaldbw
  display_name  = var.crm_ho_bu.name
}

resource "databricks_permission_assignment" "add_crm_ho_bu" {
  provider      = databricks.globaldbw
  principal_id  = data.databricks_group.crm_ho_bu.id
  permissions   = ["USER"]

  depends_on = [ data.databricks_group.crm_ho_bu ]
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

# SQL Waerhouse Sync EUR
data "databricks_sql_warehouse" "global_synceur_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-synceur-team-warehouse"
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

# SQL Warehouse Sync AMR
data "databricks_sql_warehouse" "global_syncamr_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-syncamr-team-warehouse"
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

## Cluster PA
data "databricks_cluster" "global_pa_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-pa-team-cluster"
}

resource "databricks_permissions" "global_clusterpa_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_pa_cluster.id

  access_control {
    group_name       = data.databricks_group.product_analytics_bu.display_name
    permission_level = "CAN_RESTART"
  }

  access_control {
    group_name       = data.databricks_group.product_analytics_confd_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_pa_cluster,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu
  ]
}

# SQL Waerhouse PA
data "databricks_sql_warehouse" "global_pa_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-pa-team-warehouse"
}

resource "databricks_permissions" "global_warehousepa_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_pa_warehouse.id

  access_control {
    group_name       = data.databricks_group.product_analytics_bu.display_name
    permission_level = "CAN_USE"
  }

  access_control {
    group_name       = data.databricks_group.product_analytics_confd_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_pa_warehouse,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu
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

# SQL Warehouse Applied Science
data "databricks_sql_warehouse" "global_as_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-as-team-warehouse"
}

resource "databricks_permissions" "global_warehouseas_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_as_warehouse.id

  access_control {
    group_name       = data.databricks_group.applied_science_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_as_warehouse,
    data.databricks_group.applied_science_bu
  ]
}

# Cluster CRM HO
data "databricks_cluster" "global_crmho_cluster" {
  provider      = databricks.globaldbw
  cluster_name  = "cdp-crmho-team-cluster"
}

resource "databricks_permissions" "global_clustercrmho_usage" {
  provider          = databricks.globaldbw
  cluster_id        = data.databricks_cluster.global_crmho_cluster.id

  access_control {
    group_name       = data.databricks_group.crm_ho_bu.display_name
    permission_level = "CAN_RESTART"
  }

  depends_on = [ 
    data.databricks_cluster.global_crmho_cluster,
    data.databricks_group.crm_ho_bu
  ]
}

# SQL Warehouse CRM HO
data "databricks_sql_warehouse" "global_crmho_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-crmho-team-warehouse"
}

resource "databricks_permissions" "global_warehousecrmho_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_crmho_warehouse.id

  access_control {
    group_name       = data.databricks_group.crm_ho_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_crmho_warehouse,
    data.databricks_group.crm_ho_bu
  ]
}

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

# SQL Warehouse ILA
data "databricks_sql_warehouse" "global_ila_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-ila-team-warehouse"
}

resource "databricks_permissions" "global_warehouseila_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_ila_warehouse.id

  access_control {
    group_name       = data.databricks_group.imperial_africa_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_ila_warehouse,
    data.databricks_group.imperial_africa_bu
  ]
}

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

# SQL Warehouse ILI
data "databricks_sql_warehouse" "global_ili_warehouse" {
  provider      = databricks.globaldbw
  name          = "cdp-ili-team-warehouse"
}

resource "databricks_permissions" "global_warehouseili_usage" {
  provider          = databricks.globaldbw
  sql_endpoint_id   = data.databricks_sql_warehouse.global_ili_warehouse.id

  access_control {
    group_name       = data.databricks_group.imperial_intl_bu.display_name
    permission_level = "CAN_USE"
  }

  depends_on = [ 
    data.databricks_sql_warehouse.global_ili_warehouse,
    data.databricks_group.imperial_intl_bu
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
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
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
    principal  = data.databricks_group.product_analytics_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.product_analytics_confd_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.applied_science_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.crm_ho_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_africa_bu.display_name
    privileges = ["READ_FILES"]
  }

  grant {
    principal  = data.databricks_group.imperial_intl_bu.display_name
    privileges = ["READ_FILES"]
  }

  depends_on = [
    data.databricks_group.data_engg,
    data.databricks_group.support_engg,
    data.databricks_group.super_users,
    data.databricks_group.contract_logistics_amr_bu,
    data.databricks_group.contract_logistics_eur_bu,
    data.databricks_group.product_analytics_bu,
    data.databricks_group.product_analytics_confd_bu,
    data.databricks_group.applied_science_bu,
    data.databricks_group.crm_ho_bu,
    data.databricks_group.imperial_africa_bu,
    data.databricks_group.imperial_intl_bu
  ]
}

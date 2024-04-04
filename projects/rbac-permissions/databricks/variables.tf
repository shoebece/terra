variable "tenant_id" { type = string }
variable "cdmz_subscription_id" { type = string }
variable "cdpz_dev_subscription_id" { type = string }
variable "cdpz_uat_subscription_id" { type = string }
variable "cdpz_prod_subscription_id" { type = string }

variable "data_engg_aad_group" { type = object({
  name = string
  id = string
})}

variable "engg_aad_group" { type = object({
  name = string
  id = string
})}

variable "support_engg_aad_group" { type = object({
  name = string
  id = string
})}

variable "super_user_aad_group" { type = object({
  name = string
  id = string
})}

variable "contract_logistics_amr_bu" { type = object({
  name = string
  id = string
})}

variable "contract_logistics_eur_bu" { type = object({
  name = string
  id = string
})}

variable "applied_science_bu" { type = object({
  name = string
  id = string
})}

variable "crm_ho_bu" { type = object({
  name = string
  id = string
})}

variable "imperial_africa_bu" { type = object({
  name = string
  id = string
})}

variable "imperial_intl_bu" { type = object({
  name = string
  id = string
})}

variable "pa_global_bu" { type = object({
  name = string
  id = string
})}

variable "pa_ecomm_bu" { type = object({
  name = string
  id = string
})}

variable "pa_freight_forwarding_bu" { type = object({
  name = string
  id = string
})}

variable "pa_sco_bu" { type = object({
  name = string
  id = string
})}

variable "pa_searates_bu" { type = object({
  name = string
  id = string
})}

variable "pa_trade_finance_bu" { type = object({
  name = string
  id = string
})}

variable "adf_dev_umi" { type = object({
  name = string
  app_id = string
})}

variable "adf_uat_umi" { type = object({
  name = string
  app_id = string
})}

variable "adf_prod_umi" { type = object({
  name = string
  app_id = string
})}

variable "landing_ext_loc" {
    type = list(object({
        name    = string
        stconts = list(string)
    }))
}

variable "catalog_config" {
    type = list(object({
        name    = string
        type    = string
        stconts = list(string)
    }))
}

variable "catalog_reader_permission" {type = list(string)}
variable "catalog_writer_permission" {type = list(string)}

variable "etl_notebook_path"        { type = string }
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

variable "etl_notebook_path"        { type = string }
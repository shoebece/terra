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

variable "management_spn" { type = object({
  name = string
  id = string
})}

variable old_subscription_spn { type = object({
  name = string
  id = string
})}

variable em_engg_aad_group { type = object({
  name = string
  id = string
})}

variable "cdp_synapse_admin_group" { type = object({
  name = string
  id = string
})}

variable "cdpz_internal_audit_team_group" { type = object({
  name = string
  id = string
})}
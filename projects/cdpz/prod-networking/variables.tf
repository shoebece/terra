variable "tenant_id"                        { type = string }
variable "subscription_id"                  { type = string }
variable "environment"                      { type = string }

variable "resource_location"                { type = string }

variable "resource_tags_common"             { type = map(string) }
variable "resource_tags_spec"               { type = map(string) }

# access vnet
# --------------------------------------------------------------------------------------------
variable "acc_vnet_address_space"           { type = list(string) }
variable "acc_default_snet_address_space"   { type = list(string) }
variable "acc_private_snet_address_space"   { type = list(string) }
variable "acc_public_snet_address_space"    { type = list(string) }

# global processing vnet
# --------------------------------------------------------------------------------------------
variable "proc_vnet_address_space"           { type = list(string) }
variable "proc_default_snet_address_space"   { type = list(string) }
variable "proc_private_snet_address_space"   { type = list(string) }
variable "proc_public_snet_address_space"    { type = list(string) }

variable "route_table_snets" { type = list(object({
  rgname = string
  vnet   = string
  snet   = string
})) }

variable "key_vault_pep" { type = list(object({
  rg_code = string
  kv_code = string
  ip      = string
})) }

variable "pdnsz_names"                    {type = list(string)}
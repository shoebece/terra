variable subscription_id            { type = string }
variable resource_group_name        { type = string }
variable environment                { type = string }
variable resource_location          { type = string }
variable resource_tags              { type = map(string) }

variable "stacc_name"               { type = string }
variable "stacc_full_name"          { type = string }
variable "stacc_umi_id"             { type = string }
variable "stacc_containers"         { type = list(string) }
variable "cmk_key_vault_id"         { type = string }
variable "cmk_key_name"             { type = string }

variable public_access_enabled      {
    type = bool
    default = "true"
}

variable "service_endpoint_snets"   { type = list(string) }

variable "peps"                      {
    type = list(object({
        code = string
        ip   = string
    }))
}
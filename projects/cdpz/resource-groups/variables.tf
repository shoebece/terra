variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "testprefix" { type = string }

variable "environment" { type = string }

variable "resource_location" { type = string }

variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "deploy_db_provider" {
    type = bool
    default = "false"
}

variable "deploy_vnet_provider" {
    type = bool
    default = "false"
}

variable "deploy_kv_provider" {
    type = bool
    default = "false"
}
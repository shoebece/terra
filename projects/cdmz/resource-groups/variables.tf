variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "resource_location" { type = string }

variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "deploy_pview_provider" {
    type = bool
    default = "false"
}
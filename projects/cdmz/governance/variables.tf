variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "environment" { type = string }

variable "resource_location" { type = string }

variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "sandbox_prefix" {
    type = string 
    default = ""
}

variable "purview_account_pep_ip" { type = string }
variable "purview_portal_pep_ip" { type = string }
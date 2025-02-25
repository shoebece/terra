variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "environment" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "staccs" {
    type = list(object({
        stacc = string
        pep = list(object({
            code = string
            ip   = string
        }))
        sftp_enabled = optional(bool, "false")
        stconts = list(string)
        specyfic_service_endpoint_snets = list(string)
        enable_soft_delete = bool
        soft_delete_retention_days = number
    }))
}

variable common_service_endpoint_snets {type = list(string)}

variable "sandbox_prefix" {
    type = string
    default = ""
}

variable public_access_enabled {
    type = bool
    default = "true"
}
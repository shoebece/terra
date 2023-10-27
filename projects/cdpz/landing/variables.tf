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
        stconts = list(string)
    }))
}

variable "sandbox_prefix" {
    type = string
    default = ""
}

variable public_access_enabled {
    type = bool
    default = "true"
}
variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "cdmz_subscription_id" { type = string }
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
    }))
}

variable service_endpoint_snets {type = list(object({
    rgname = string
    vnet = string
    snet = string
}))}

variable cdmz_service_endpoint_snets {type = list(object({
    rgname = string
    vnet = string
    snet = string
}))}

variable "sandbox_prefix" {
    type = string 
    default = ""
}

variable public_access_enabled {
    type = bool
    default = "true"
}
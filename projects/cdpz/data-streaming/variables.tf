variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "cdmz_subscription_id" { type = string }
variable "environment" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "private_endpoint_ip_address" { type = string }

variable "service_endpoint_snets" { type = list(object({
  rgname = string
  vnet   = string
  snet   = string
})) }

variable cdmz_service_endpoint_snets {type = list(object({
    rgname = string
    vnet = string
    snet = string
}))}
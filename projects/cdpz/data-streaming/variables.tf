variable "tenant_id" { type = string }
variable "subscription_id" { type = string }
variable "cdmz_subscription_id" { type = string }
variable "environment" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }
variable "resource_tags_ila_opsi" { type = map(string) }

variable "private_endpoint_ip_address" { type = string }
variable "private_endpoint_ip_address_ilamix" { type = string }
variable "private_endpoint_ip_address_ila_opsi" { type = string }

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

variable "strg_tiot_delayed" { type = string }
variable "strg_tiot_error" { type = string }
variable "strg_tiot_event" { type = string }
variable "strg_tiot_uptime" { type = string }
variable "strg_events" { type = string }
variable "strg_positions" { type = string }
variable "strg_trips" { type = string }
variable "strg_workflow_events" { type = string }
variable "strg_workflow_states" { type = string }
variable "strg_opsi_test" { type = string }
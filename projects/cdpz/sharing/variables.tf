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

variable "allowed_ips"  { type = list(object({
  name = string
  start_ip_address = string
  end_ip_address = string
}))}

variable "aad_admin_login" { type = string }
variable "aad_admin_object_id" { type = string }

variable "synapse_sql_on_demand_pep_ip_address" { type = string }

variable "admin_pass" { type = string }
variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "vms_fivetran" {
  type = list(object({
    vm             = string
    ip             = string
    computer_name  = string
    admin_username = string
    admin_password = string
  }))
}

variable "super_user_aad_group"      { type = object({
  name = string
  id = string
})}

variable "sql_private_endpoint_ip_address"  { type = string }
variable "admin_pass"                       { type = string }



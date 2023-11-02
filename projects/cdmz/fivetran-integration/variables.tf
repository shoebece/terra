variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "fivetran_sql_dbs" { 
  type = list(object({
    name = string
  })) 
}

variable "vm_admin_password" { type = string }

variable "vms_fivetran" {
  type = list(object({
    vm             = string
    ip             = string
    computer_name  = string
    admin_username = string
  }))
}

variable "super_user_aad_group"      { type = object({
  name = string
  id = string
})}

variable "sql_private_endpoint_ip_address"  { type = string }
variable "sql_admin_password"               { type = string }



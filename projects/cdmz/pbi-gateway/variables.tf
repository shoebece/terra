variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }

variable "vms" {
  type = list(object({
    vm             = string
    ip             = string
    computer_name  = string
    admin_username = string
    admin_password = string
  }))
}

variable "resource_group_name" { type = string }
variable "networking_resource_group_name" { type = string }
variable "vnet_name" { type = string }
variable "snet_name" { type = string }

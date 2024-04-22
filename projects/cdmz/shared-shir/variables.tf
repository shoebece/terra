variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "private_endpoint_ip_address" { type = string }
variable "portal_private_endpoint_ip_address" { type = string }

variable "resource_location" { type = string }
variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }
variable "resource_ospatching_tags_spec" { type = map(string) }


variable "git_integration" {
  type    = bool
  default = false
}
variable "git_tenant_id" {
  type    = string
  default = ""
}
variable "git_account_name" {
  type    = string
  default = ""
}
variable "git_project_name" {
  type    = string
  default = ""
}
variable "git_repository_name" {
  type    = string
  default = ""
}
variable "git_root_folder" {
  type    = string
  default = ""
}
variable "git_branch_name" {
  type    = string
  default = ""
}

variable "admin_password" { type = string }

variable "vms" {
  type = list(object({
    vm             = string
    ip             = string
    computer_name  = string
    admin_username = string
    size           = string
    disk_sku       = string
    disk_size_gb   = number
  }))
}

variable "linuxvms" {
  type = list(object({
    vm             = string
    ip             = string
    computer_name  = string
    admin_username = string
    size           = string
    disk_sku       = string
    disk_size_gb   = number
  }))
}
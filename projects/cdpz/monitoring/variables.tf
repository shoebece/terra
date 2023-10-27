variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "environment" { type = string }

variable "resource_location" { type = string }
variable "resource_group_name" { type = string }

# variable "shared_shir_adf_name" { type = string }
# variable "shared_shir_adf_rg" { type = string }

variable "management_kv_name" { type = string }
variable "management_kv_rg" { type = string }

variable "management_dbw_name" { type = string }
variable "management_dbw_rg" { type = string }

variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }
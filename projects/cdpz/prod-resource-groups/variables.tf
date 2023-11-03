variable "tenant_id" { type = string }
variable "subscription_id" { type = string }

variable "environment" { type = string }

variable "resource_location" { type = string }

variable "resource_tags_common" { type = map(string) }
variable "resource_tags_spec" { type = map(string) }
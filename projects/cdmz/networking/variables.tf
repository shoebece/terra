variable "tenant_id"                    { type = string }
variable "subscription_id"              { type = string }
variable "resource_location"            { type = string }

variable "resource_tags_common"         { type = map(string) }
variable "resource_tags_spec"           { type = map(string) }

variable "deploy_network_watcher"       { 
                                            type = bool
                                            default = "true"
                                        }

# vnet
# ----------------------------------------
variable "vnet_address_space"           {type = list(string)}
variable "default_snet_address_space"   {type = list(string)}
variable "private_snet_address_space"   {type = list(string)}
variable "public_snet_address_space"    {type = list(string)}

variable "route_table_snets" { type = list(object({
  rgname = string
  vnet   = string
  snet   = string
})) }

variable "firewall_ip_address"           { type = string }
variable "vpn_firewall_ip_address"       { type = string }
variable "kv_ip_address"                 { type = string }
variable "synapse_plhub_ip_address"      { type = string }
variable "EUR_Int_firewall_ip_address"      { type = string }
variable "uae-cpperimeter81-prod"      { type = string }

variable "sandbox_prefix" {
    type = string 
    default = ""
}

variable "pdnsz_names"                    {type = list(string)}
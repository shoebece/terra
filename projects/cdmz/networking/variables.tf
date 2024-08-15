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
variable "AMR_Int_firewall_ip_address"      { type = string }
variable "uae-cpperimeter81-prod"      { type = string }
variable "kv_fv_ip_address"                 { type = string }
variable "ecommSQL_fv_ip_address"                 { type = string }
variable "BerthPlanningApplication_fv_ip_address" { type = string }
variable "DPWFoundationalServicesProd_fv_ip_address" { type = string }
variable "cargoesflow_fv_ip_address"  { type = string }
variable "TradeFinance_fv_ip_address"  { type = string }
variable "CargoesLogistics_fv_ip_address"  { type = string }
variable "datalakestrprod_fv_ip_address"  { type = string }
variable "datalakestrprod_dfs_fv_ip_address"  { type = string }
variable "pgecommipms_fv_ip_address"  { type = string }
variable "mysql-nau-dr_fv_ip_address"  { type = string }
variable "btdr_firewall_ip_address"           { type = string }
# variable "CCSMEA_fv_ip_address"           { type = string }
variable "CCSGlobal_fv_ip_address"           { type = string }
variable "DTWorld_fv_ip_address"           { type = string }
variable "POEMSSQL_fv_ip_address"                 { type = string }
variable "BASQL_fv_ip_address"                 { type = string }
variable "mpowered_fv_ip_address"                 { type = string }
variable "AzureSQL_cargoesrunnerprod_fv_ip_address"                 { type = string }
variable "casmosmongo_fv_ip_address"                 { type = string }
variable "sandbox_prefix" {
    type = string 
    default = ""
}

variable "pdnsz_names"                    {type = list(string)}

#pep for MSQL Server
variable "msql" {
    type = list(object({
        pep = list(object({
            code = string
            ip   = string
            name   = string
            resource_group_name = string
            provider  = string
            pepsql = string
            subscription = string
        }))

    }))
}
data "azurerm_resource_group" "resgrp" {
  name      = "cdmz-networking-rg"
}

data "azurerm_resource_group" "resgrpfv" {
  name      = "cdmz-mgmt-fivetran-rg"
}

resource "azurerm_network_watcher" "netw" {
  count = var.deploy_network_watcher ? 1 : 0
  
  name = join("-", ["cdpz-nwwatcher", var.resource_location])

  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  tags = merge(var.resource_tags_common, var.resource_tags_spec)
}

resource "azurerm_private_dns_zone" "dnss" {
  for_each            = toset(var.pdnsz_names)

  name                = each.key
  resource_group_name = data.azurerm_resource_group.resgrp.name

  tags = merge(var.resource_tags_common, var.resource_tags_spec)

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

module "vnet" {
  source   = "../../../modules/network"

  vnet_name = "cdmz-management-vnet"
  nsg_name = "cdmz-management-nsg" 

  resource_group_name = data.azurerm_resource_group.resgrp.name
  resource_location   = var.resource_location
  resource_tags       = merge(var.resource_tags_common, var.resource_tags_spec)

  vnet_purpose  = "management"

  vnet_address_space          = var.vnet_address_space
  default_snet_address_space  = var.default_snet_address_space
  private_snet_address_space  = var.private_snet_address_space
  public_snet_address_space   = var.public_snet_address_space

  pdnsz_names                 = var.pdnsz_names

  depends_on = [
    azurerm_private_dns_zone.dnss
  ]
}

data "azurerm_virtual_network" "vnet" {
  name     =  "cdmz-management-vnet"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

data "azurerm_subnet" "route-table-snet" {
  count                 = length(var.route_table_snets)

  resource_group_name   = var.route_table_snets[count.index].rgname
  virtual_network_name  = var.route_table_snets[count.index].vnet
  name                  = var.route_table_snets[count.index].snet

  depends_on = [ module.vnet ]
}

resource "azurerm_route_table" "art" {
  name                          = "cdmz-management-rt"
  resource_group_name           = data.azurerm_resource_group.resgrp.name
  location                      = var.resource_location
  
  disable_bgp_route_propagation = false

  route = [
    {
      name                    = "powerbi"
      address_prefix          = "PowerBI"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_Algiers_Fivetran_1"
      address_prefix          = "192.168.10.106/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_batangas_Fivetran_con"
      address_prefix          = "10.2.0.51/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Dakar_Fivetran_1"
      address_prefix          = "10.52.6.99/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Dakar_Fivetran_2"
      address_prefix          = "10.52.6.62/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Jeddah_FiveTran"
      address_prefix          = "192.168.203.0/24"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Berbera_Fivetran"
      address_prefix          = "10.10.100.225/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },

    {
      name                    = "Route_Posorja_Fivetran"
      address_prefix          = "10.24.1.61/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_UAE_SEC_DLP_ME_VA"
      address_prefix          = "10.254.7.0/24"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_SEC_CheckPoint_EDR"
      address_prefix          = "10.254.4.4/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_AOLAD_Fivetran"
      address_prefix          = "172.22.18.4/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.EUR_Int_firewall_ip_address
    },
    {
      name                    = "Route_P81_Lirquin_FiveTran_3"
      address_prefix          = "10.11.23.65/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_SanAntonio_Connector_1"
      address_prefix          = "10.11.40.177/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_SanAntonio_FiveTran_1"
      address_prefix          = "10.11.40.31/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_SanAntonio_FiveTran_3"
      address_prefix          = "10.11.40.35/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_SanAntonio_FiveTran_4"
      address_prefix          = "10.11.43.31/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_S2S_VPN_FiveTran_CCT"
      address_prefix          = "10.91.30.64/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Constanta_Fivetran"
      address_prefix          = "192.168.24.44/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_LCIT_Fivetran"
      address_prefix          = "172.19.240.120/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_Pusan_Fivetran"
      address_prefix          = "10.2.2.105/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_ANZ_Fivetran"
      address_prefix          = "10.0.6.10/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_rotterdam_Fivetran"
      address_prefix          = "10.168.100.22/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_cdpz-dev-processing-vnet"
      address_prefix          = "10.220.200.0/23"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_cdpz-uat-processing-vnet"
      address_prefix          = "10.220.208.0/23"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_cdpz-prod-processing-vnet"
      address_prefix          = "10.220.216.0/23"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_cdpz-prod-access-vnet"
      address_prefix          = "10.220.226.0/23"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_cdpz-global-processing-vnet"
      address_prefix          = "10.220.228.0/23"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_Antwerp_Fivetran"
      address_prefix          = "185.47.68.34/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
    {
      name                    = "Route_SCO_Fivetran"
      address_prefix          = "10.91.5.58/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_psql-cargoeslogisticsabbs-prod"
      address_prefix          = "10.2.161.0/25"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.EUR_Int_firewall_ip_address
    },
    {
      name                    = "Route_psql-trackingservice-prod"
      address_prefix          = "10.143.68.0/28"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    }
  ]
    
  tags = merge(var.resource_tags_common, var.resource_tags_spec)
}

resource "azurerm_subnet_route_table_association" "rt-snets-ass" {
  count           = length(data.azurerm_subnet.route-table-snet)

  subnet_id      = data.azurerm_subnet.route-table-snet[count.index].id
  route_table_id  = azurerm_route_table.art.id

  depends_on = [ 
    azurerm_route_table.art
    ,data.azurerm_subnet.route-table-snet
  ]  
}

data "azurerm_subnet" "snet-default" {
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  virtual_network_name  = "cdmz-management-vnet"
  name                  = "management-default-snet"

  depends_on = [ module.vnet ]
}

data "azurerm_key_vault" "kv" {
  name                = var.sandbox_prefix == "" ? "cdmz-management-kv" : "cdmz-${var.sandbox_prefix}-management-akv"
  resource_group_name = "cdmz-management-rg"
}

data "azurerm_key_vault" "kvfv" {
  name                = "cdmz-mgmt-fivetran-kv"
  resource_group_name = "cdmz-mgmt-fivetran-rg"
}

data "azurerm_mssql_server" "AzureSQL_Ecomm" {
  name                = "sqlprdecomm"
  resource_group_name = "rg-ecommerce-prod"
  provider            = azurerm.Ecommerce
}

data "azurerm_postgresql_server" "AzurePSQL_BerthPlanningApplication" {
  name                = "psql-bpa-prod"
  resource_group_name = "rg-bpa-prod"
  provider            = azurerm.BerthPlanningApplication
}

data "azurerm_postgresql_server" "AzurePSQL_DPWFoundationalServicesProd" {
  name                = "cargoes-platform-prod-postgresql-server-dr"
  resource_group_name = "cargoes-prod"
  provider            = azurerm.DPWFoundationalServicesProd
}

data "azurerm_postgresql_server" "AzurePSQL_CargoesFlow" {
  name                = "pg-cargoesflow-prod1-dr"
  resource_group_name = "rg-cargoesflow-prod"
  provider            = azurerm.CargoesFlow
}

data "azurerm_postgresql_server" "AzurePSQL_TradeFinance" {
  name                = "psql-cargoes-finance-postgres-prod-dr"
  resource_group_name = "rg-cargoes-finance-prod"
  provider            = azurerm.TradeFinance
}

data "azurerm_postgresql_server" "AzurePSQL_CargoesLogistics" {
  name                = "psql-cargoeslogistics-prod-dr"
  resource_group_name = "rg-cargoeslogistics-prod-dr"
  provider            = azurerm.CargoesLogistics
}

data "azurerm_storage_account" "AzureStorage_BusinessAnalytics" {
  name                = "datalakestrprod"
  resource_group_name = "rg-ba-lake-prod-uaenorth"
  provider            = azurerm.BusinessAnalytics
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name

  depends_on = [ azurerm_private_dns_zone.dnss ]
}

data "azurerm_private_dns_zone" "pdnsz_sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  depends_on = [ azurerm_private_dns_zone.dnss ]
}

data "azurerm_private_dns_zone" "pdnsz_blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  depends_on = [ azurerm_private_dns_zone.dnss ]
}

data "azurerm_private_dns_zone" "pdnsz_dfs" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  depends_on = [ azurerm_private_dns_zone.dnss ]
}
# Private end point management key vault
resource "azurerm_private_endpoint" "kv_endpoint" {
  name                = "cdmz-management-kv-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-management-kv-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                           = "cdmz-management-kv-psc"
    private_connection_resource_id = data.azurerm_key_vault.kv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-management-kv-ipc"
    private_ip_address = var.kv_ip_address
    subresource_name   = "vault"
    member_name        = "default"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    data.azurerm_private_dns_zone.pdnsz
  ]
}

# Private end point management key vault for FiveTran

resource "azurerm_private_endpoint" "kv_endpoint_fv" {
  name                = "cdmz-mgmt-fivetran-kv-pep"
  resource_group_name = data.azurerm_resource_group.resgrpfv.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-kv-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-kv-psc"
    private_connection_resource_id = data.azurerm_key_vault.kvfv.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-kv-ipc"
    private_ip_address = var.kv_fv_ip_address
    subresource_name   = "vault"
    member_name        = "default"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    data.azurerm_private_dns_zone.pdnsz
  ]
}

# Private end point management for Azure SQL Ecomm
resource "azurerm_private_endpoint" "AzureSQL_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-ecommSQL-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-ecommSQL-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_mssql_server.AzureSQL_Ecomm.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-ecommSQL-ipc"
    private_ip_address = var.ecommSQL_fv_ip_address
    subresource_name   = "sqlServer"
    member_name        = "sqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    data.azurerm_private_dns_zone.pdnsz
  ]
}

# Private dns creation for postgres and linked to CDP Management VNET

resource "azurerm_private_dns_zone" "pdnsz_psql" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "psqldnss-vnet-link" {
  name                  = "pdnsz_psql-link"
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz_psql.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone" "pdnsz_flex_psql" {
  name                = "private.postgres.database.azure.com"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "psqldnsss-vnet-link" {
  name                  = "pdnsz_flex_psql-link"
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz_flex_psql.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

# Private end point management for PostgreSQL single server psql-bpa-prod
resource "azurerm_private_endpoint" "AzurePSQL_BP_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-BerthPlanningApplication-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-BerthPlanningApplication-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_BerthPlanningApplication.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-BerthPlanningApplication-ipc"
    private_ip_address = var.BerthPlanningApplication_fv_ip_address
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    azurerm_private_dns_zone.pdnsz_psql
  ]
}

# Private end point management for PostgreSQL single server cargoes-platform-prod-postgresql-server-dr
resource "azurerm_private_endpoint" "AzurePSQL_cpp_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_DPWFoundationalServicesProd.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-ipc"
    private_ip_address = var.DPWFoundationalServicesProd_fv_ip_address
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    azurerm_private_dns_zone.pdnsz_psql
  ]
}

# Private end point management for PostgreSQL single server pg-cargoesflow-prod1-dr

resource "azurerm_private_endpoint" "AzurePSQL_cargoesflow_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-cargoesflow-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-cargoesflow-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_CargoesFlow.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-cargoesflow-ipc"
    private_ip_address = var.cargoesflow_fv_ip_address
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    azurerm_private_dns_zone.pdnsz_psql
  ]
}

# Private end point management for PostgreSQL single server psql-cargoes-finance-postgres-prod-dr
resource "azurerm_private_endpoint" "AzurePSQL_TradeFinance_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-TradeFinance-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-TradeFinance-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_TradeFinance.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-TradeFinance-ipc"
    private_ip_address = var.TradeFinance_fv_ip_address
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    azurerm_private_dns_zone.pdnsz_psql
  ]
}

# # Private end point management for PostgreSQL single server psql-cargoeslogistics-prod-dr
resource "azurerm_private_endpoint" "AzurePSQL_CargoesLogistics_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-CargoesLogistics-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-CargoesLogistics-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_CargoesLogistics.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-CargoesLogistics-ipc"
    private_ip_address = var.CargoesLogistics_fv_ip_address
    subresource_name   = "postgresqlServer"
    member_name        = "postgresqlServer"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    azurerm_private_dns_zone.pdnsz_psql
  ]
}

#private endpoint connection to the BA datalakestrprod - RITM0091858 - DL to DL One time Copy via ADF

resource "azurerm_private_endpoint" "AzureStorage_BusinessAnalytics_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-datalakestrprodblob-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-datalakestrprodblob-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_AzureStorage"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_blob.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_storage_account.AzureStorage_BusinessAnalytics.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-AzureStorageblob-ipc"
    private_ip_address = var.datalakestrprod_fv_ip_address
    subresource_name   = "blob"
    member_name        = "blob"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    data.azurerm_private_dns_zone.pdnsz
  ]
}

#private endpoint connection to the BA datalakestrprod for DFS - RITM0091858 - DL to DL One time Copy via ADF
resource "azurerm_private_endpoint" "AzureStorage_dfs_BusinessAnalytics_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-datalakestrproddfs-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-datalakestrproddfs-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_AzureStorage"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_dfs.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_dfs-psc"
    private_connection_resource_id = data.azurerm_storage_account.AzureStorage_BusinessAnalytics.id
    subresource_names              = ["dfs"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-AzureStoragedfs-ipc"
    private_ip_address = var.datalakestrprod_dfs_fv_ip_address
    subresource_name   = "dfs"
    member_name        = "dfs"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [
    data.azurerm_subnet.snet-default,
    data.azurerm_private_dns_zone.pdnsz
  ]
}


resource "azurerm_virtual_network_peering" "hub_peer" {
  name                      = "peer-hub-to-cdp-management"
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  virtual_network_name      = module.vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
  allow_forwarded_traffic   = "true"
}

resource "azurerm_virtual_network_peering" "EURhub_peer" {
  name                      = "peer-EURHub-to-cdp-management"
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  virtual_network_name      = module.vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1b37d994-cdaf-4d33-b73d-afb406d36357/resourceGroups/rg-eur-sechub/providers/Microsoft.Network/virtualNetworks/EUR-Vnetsechub"     
  allow_forwarded_traffic   = "true"
}

resource "azurerm_synapse_private_link_hub" "syn_plh" {
  name                = "cdmzmanagementsynapseplhub"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

data "azurerm_private_dns_zone" "syn_web_pdnsz" {
  name                = "privatelink.azuresynapse.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name

  depends_on = [ azurerm_private_dns_zone.dnss ]
}

# Private end point synapse private link hub
resource "azurerm_private_endpoint" "syn_plh_endpoint" {
  name                = "cdmz-management-synapse-plhub-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-management-synapse-plhub-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.syn_web_pdnsz.id ]
  }

  private_service_connection {
    name                           = "cdmz-management-synapse-plhub-psc"
    private_connection_resource_id = azurerm_synapse_private_link_hub.syn_plh.id
    subresource_names              = ["web"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-management-synapse-plhub-ipc"
    private_ip_address = var.synapse_plhub_ip_address
    subresource_name   = "web"
    member_name        = "web"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id
    ]
  }

  depends_on = [ 
    data.azurerm_subnet.snet-default
    ,azurerm_synapse_private_link_hub.syn_plh
    ,data.azurerm_private_dns_zone.syn_web_pdnsz
  ]
}
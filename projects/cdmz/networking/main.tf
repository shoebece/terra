locals {
  networking_resource_group_name = join("-", ["cdmz","networking-rg"])
  msql_peps = flatten([
    for msql in var.msql : [
        for pep in msql.pep : {
          key       = join("-", [pep.pepsql, pep.code, "pep"])
          pepsql    = pep.pepsql
          pep_code  = pep.code
          pep_ip    = pep.ip
          name      = pep.name
          resource_group_name = pep.resource_group_name
          provider  = pep.provider
          subscription = pep.subscription
        }
    ]
  ])
}

# locals {
#   provider_map = {
#     DryDocks = azurerm.DryDocks
#     # Dpworld = azurerm.Dpworld
#   }
# }


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
  
  disable_bgp_route_propagation = var.disable_bgp_route_propagation

  dynamic "route" {
    for_each = var.routes
    content {
      name                   = route.key
      address_prefix         = route.value.address_prefix
      next_hop_type          = route.value.next_hop_type
      next_hop_in_ip_address = route.value.next_hop_in_ip_address
    }
  }
  tags = merge(var.resource_tags_common, var.resource_tags_spec)
  lifecycle {
    ignore_changes = [
      route
    ]
  }
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

data "azurerm_postgresql_server" "AzurePSQL_Ecomm" {
  name                = "pgecommipms-prod-dr"
  resource_group_name = "rg-ecommerce-prod-dr"
  provider            = azurerm.Ecommerce
}

data "azurerm_postgresql_flexible_server" "AzurePSQL_BerthPlanningApplication" {
  name                = "pg-bpa-prod"
  resource_group_name = "rg-bpa-prod"
  provider            = azurerm.BerthPlanningApplication
}

# data "azurerm_postgresql_flexible_server" "AzurePSQL_DPWFoundationalServicesProd" {
#   name                = "cargoes-platform-prod-postgres-flexible-dr"
#   resource_group_name = "cargoes-prod"
#   provider            = azurerm.DPWFoundationalServicesProd
# }

# data "azurerm_postgresql_flexible_server" "AzurePSQL_CargoesFlow" {
#   name                = "psql-cargoesflow-prod-dr"
#   resource_group_name = "rg-cargoesflow-prod-dr"
#   provider            = azurerm.CargoesFlow
# }

data "azurerm_postgresql_flexible_server" "AzurePSQL_TradeFinance" {
  name                = "psql-tradefinance-prod-dr"
  resource_group_name = "rg-cargoes-finance-prod-dr"
  provider            = azurerm.TradeFinance
}

data "azurerm_postgresql_flexible_server" "AzurePSQL_CargoesLogistics" {
  name                = "psql-cargoeslogistics-flex-dr-03"
  resource_group_name = "rg-cargoeslogistics-prod"
  provider            = azurerm.CargoesLogistics
}

data "azurerm_storage_account" "AzureStorage_BusinessAnalytics" {
  name                = "datalakestrprod"
  resource_group_name = "rg-ba-lake-prod-uaenorth"
  provider            = azurerm.BusinessAnalytics
}

data "azurerm_mysql_flexible_server" "AzureMysql_mysql-naudb-prod-dr" {
  name                = "mysql-naudb-prod-dr"
  resource_group_name = "Rg-nau-production"
  provider            = azurerm.NAU
}

data "azurerm_cosmosdb_account" "cosmongo_cargoeslogistics" {
  name                = "cosmos-cargoeslogisitcs-production"
  resource_group_name = "rg-cargoeslogistics-prod"
  provider            = azurerm.CargoesLogistics
}

# data "azurerm_mysql_server" "AzureMysql_mysql-mea-dr" {
#   name                = "mysql-mea-dr"
#   resource_group_name = "rg-mea-prod"
#   provider            = azurerm.CCSMEA
# }

data "azurerm_mysql_flexible_server" "AzureMysql_mysql-global-dr" {
  name                = "mysql-global-dr"
  resource_group_name = "rg-global-prod"
  provider            = azurerm.CCSGlobal
}

data "azurerm_mysql_flexible_server" "AzureMysql_mysql-accounts-prod-dr" {
  name                = "mysql-accountsprod-dr"
  resource_group_name = "rg-accountsproduction"
  provider            = azurerm.DTWorld
}

data "azurerm_mssql_server" "AzureSQL_POEMS" {
  name                = "sqlrostimauae-dr"
  resource_group_name = "Rg-RostimaUAE-DR"
  provider            = azurerm.POEMS
}

data "azurerm_mssql_server" "AzureSQL_ormsprod" {
  name                = "orms"
  resource_group_name = "orms"
  provider            = azurerm.orms
}

data "azurerm_mssql_server" "AzureSQL_cargoesrunnerprod" {
  name                = "sql-cargoesrunnerprod-uaereplica"
  resource_group_name = "rg_cargoesRunner_prod"
  provider            = azurerm.CargoesRunner
}

data "azurerm_mssql_server" "AzureSQL_BASQL" {
  name                = "ba-sqlprod"
  resource_group_name = "Rg-sqlbamanagedprod"
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

# Private end point management for Azure SQL Cargoes Runner SQL

resource "azurerm_private_endpoint" "AzureSQLRunner_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-CargoesRunnerSQL-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-CargoesRunnerSQL-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_mssql_server.AzureSQL_cargoesrunnerprod.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-AzureSQL_cargoesrunnerprod-ipc"
    private_ip_address = var.AzureSQL_cargoesrunnerprod_fv_ip_address
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

# Private dns creation for mongo and linked to CDP Management VNET

resource "azurerm_private_dns_zone" "pdnsz_mongo" {
  name                = "privatelink.mongo.cosmos.azure.com"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mongodnss-vnet-link" {
  name                  = "pdnsz_mongo-link"
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz_mongo.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
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

resource "azurerm_private_dns_zone" "pdnsz_mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdnsz-mysql-vnet-link" {
  name                  = "pdnsz_mysql-link"
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz_mysql.name
  virtual_network_id    = data.azurerm_virtual_network.vnet.id
}

resource "azurerm_private_dns_zone" "pdnsz_flex_mysql" {
  name                = "private.mysql.database.azure.com"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "pdnsz-flex-mysql-vnet-link" {
  name                  = "pdnsz_flex_mysql-link"
  resource_group_name   = data.azurerm_resource_group.resgrp.name
  private_dns_zone_name = azurerm_private_dns_zone.pdnsz_flex_mysql.name
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
    private_connection_resource_id = data.azurerm_postgresql_flexible_server.AzurePSQL_BerthPlanningApplication.id
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

# # Private end point management for PostgreSQL single server cargoes-platform-prod-postgresql-server-dr
# resource "azurerm_private_endpoint" "AzurePSQL_cpp_endpoint_pep" {
#   name                = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-pep"
#   resource_group_name = data.azurerm_resource_group.resgrp.name
#   location            = var.resource_location

#   subnet_id = data.azurerm_subnet.snet-default.id

#   custom_network_interface_name = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-nic"

#   private_dns_zone_group {
#     name = "add_to_azure_private_dns_psql"
#     private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
#   }
  
#   private_service_connection {
#     name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
#     private_connection_resource_id = data.azurerm_postgresql_flexible_server.AzurePSQL_DPWFoundationalServicesProd.id
#     subresource_names              = ["postgresqlServer"]
#     is_manual_connection           = false
#   }

#   ip_configuration {
#     name               = "cdmz-mgmt-fivetran-DPWFoundationalServicesProd-ipc"
#     private_ip_address = var.DPWFoundationalServicesProd_fv_ip_address
#     subresource_name   = "postgresqlServer"
#     member_name        = "postgresqlServer"
#   }

#   tags = merge(
#     var.resource_tags_spec
#   )

#   lifecycle {
#     ignore_changes = [
#       subnet_id
#     ]
#   }

#   depends_on = [
#     data.azurerm_subnet.snet-default,
#     azurerm_private_dns_zone.pdnsz_psql
#   ]
# }

# Private end point management for PostgreSQL single server pg-cargoesflow-prod1-dr

# resource "azurerm_private_endpoint" "AzurePSQL_cargoesflow_endpoint_pep" {
#   name                = "cdmz-mgmt-fivetran-cargoesflow-pep"
#   resource_group_name = data.azurerm_resource_group.resgrp.name
#   location            = var.resource_location

#   subnet_id = data.azurerm_subnet.snet-default.id

#   custom_network_interface_name = "cdmz-mgmt-fivetran-cargoesflow-nic"

#   private_dns_zone_group {
#     name = "add_to_azure_private_dns_psql"
#     private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
#   }
  
#   private_service_connection {
#     name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
#     private_connection_resource_id = data.azurerm_postgresql_flexible_server.AzurePSQL_CargoesFlow.id
#     subresource_names              = ["postgresqlServer"]
#     is_manual_connection           = false
#   }

#   ip_configuration {
#     name               = "cdmz-mgmt-fivetran-cargoesflow-ipc"
#     private_ip_address = var.cargoesflow_fv_ip_address
#     subresource_name   = "postgresqlServer"
#     member_name        = "postgresqlServer"
#   }

#   tags = merge(
#     var.resource_tags_spec
#   )

#   lifecycle {
#     ignore_changes = [
#       subnet_id
#     ]
#   }

#   depends_on = [
#     data.azurerm_subnet.snet-default,
#     azurerm_private_dns_zone.pdnsz_psql
#   ]
# }

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
    private_connection_resource_id = data.azurerm_postgresql_flexible_server.AzurePSQL_TradeFinance.id
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

# # Private end point management for PostgreSQL flex server psql-cargoeslogistics-flex-dr-03
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
    private_connection_resource_id = data.azurerm_postgresql_flexible_server.AzurePSQL_CargoesLogistics.id
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

# # Private end point management for PostgreSQL single server psql-cargoeslogistics-prod-dr
resource "azurerm_private_endpoint" "AzurePSQL_pgecommipms_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-pgecommipms-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-pgecommipms-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.AzurePSQL_Ecomm.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-pgecommipms-ipc"
    private_ip_address = var.pgecommipms_fv_ip_address
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

# # Private end point management for MySQl single server mysql-nau-dr

resource "azurerm_private_endpoint" "AzureMysql_mysql_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-mysql-naudb-prod-dr-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-mysql-naudb-prod-dr-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_mysql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_mysql-psc"
    private_connection_resource_id = data.azurerm_mysql_flexible_server.AzureMysql_mysql-naudb-prod-dr.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-mysql-naudb-prod-dr-ipc"
    private_ip_address = var.mysql-nau-dr_fv_ip_address
    subresource_name   = "mysqlServer"
    member_name        = "mysqlServer"
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
    azurerm_private_dns_zone.pdnsz_mysql
  ]
}

# # # Private end point management for MySQl single server mysql-mea-dr
# resource "azurerm_private_endpoint" "AzureMysql_meadb_mysql_endpoint_pep" {
#   name                = "cdmz-mgmt-fivetran-mysql-meadb-prod-dr-pep"
#   resource_group_name = data.azurerm_resource_group.resgrp.name
#   location            = var.resource_location

#   subnet_id = data.azurerm_subnet.snet-default.id

#   custom_network_interface_name = "cdmz-mgmt-fivetran-mysql-meadb-prod-dr-nic"

#   private_dns_zone_group {
#     name = "add_to_azure_private_dns_psql"
#     private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_mysql.id ]
#   }
  
#   private_service_connection {
#     name                           = "cdmz-mgmt-fivetran-pdnsz_mysql-psc"
#     private_connection_resource_id = data.azurerm_mysql_server.AzureMysql_mysql-mea-dr.id
#     subresource_names              = ["mysqlServer"]
#     is_manual_connection           = false
#   }

#   ip_configuration {
#     name               = "cdmz-mgmt-fivetran-mysql-meadb-prod-dr-ipc"
#     private_ip_address = var.CCSMEA_fv_ip_address
#     subresource_name   = "mysqlServer"
#     member_name        = "mysqlServer"
#   }

#   tags = merge(
#     var.resource_tags_spec
#   )

#   lifecycle {
#     ignore_changes = [
#       subnet_id
#     ]
#   }

#   depends_on = [
#     data.azurerm_subnet.snet-default,
#     azurerm_private_dns_zone.pdnsz_mysql
#   ]
# }

# # Private end point management for MySQl flex server mysql-global-dr

resource "azurerm_private_endpoint" "AzureMysql_globaldb_mysql_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-mysql-globaldb-prod-dr-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-mysql-globaldb-prod-dr-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_mysql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_mysql-psc"
    private_connection_resource_id = data.azurerm_mysql_flexible_server.AzureMysql_mysql-global-dr.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-mysql-globaldb-prod-dr-ipc"
    private_ip_address = var.CCSGlobal_fv_ip_address
    subresource_name   = "mysqlServer"
    member_name        = "mysqlServer"
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
    azurerm_private_dns_zone.pdnsz_mysql
  ]
}

# # Private end point management for MySQl single server mysql-accounts-prod-dr
resource "azurerm_private_endpoint" "AzureMysql_accountsdb_mysql_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-mysql-accountsdb-prod-dr-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-mysql-accountsdb-prod-dr-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_mysql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_mysql-psc"
    private_connection_resource_id = data.azurerm_mysql_flexible_server.AzureMysql_mysql-accounts-prod-dr.id
    subresource_names              = ["mysqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-mysql-accountsdb-prod-dr-ipc"
    private_ip_address = var.DTWorld_fv_ip_address
    subresource_name   = "mysqlServer"
    member_name        = "mysqlServer"
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
    azurerm_private_dns_zone.pdnsz_mysql
  ]
}

# # Private end point management for SQL Server - sqlprdrostimadbserver-dr

resource "azurerm_private_endpoint" "AzureSQL_POEMS_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-PoemsSQL-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-PoemsSQL-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_mssql_server.AzureSQL_POEMS.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-PoemsSQL-ipc"
    private_ip_address = var.POEMSSQL_fv_ip_address
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
# # Private end point management for SQL Server - orms

resource "azurerm_private_endpoint" "AzureSQL_Orms_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-ORMSSQL-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-ORMSSQL-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_mssql_server.AzureSQL_ormsprod.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-ormsSQL-ipc"
    private_ip_address = var.ORMSSQL_fv_ip_address
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


# # Private end point management for SQL Server - ba-sqlprod
resource "azurerm_private_endpoint" "AzureSQL_BASQL_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-BaSQL-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-BaSQL-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = data.azurerm_mssql_server.AzureSQL_BASQL.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-BaSQL-ipc"
    private_ip_address = var.BASQL_fv_ip_address
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

# Private end point management for Azure Cosmos DB for MongoDB account cosmos-cargoeslogisitcs-production

resource "azurerm_private_endpoint" "AzureCosmongo_cargoeslogistics_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-cosmongo-cargoeslogistics-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-cosmongo-cargoeslogistics-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_mongo.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_mongo-psc"
    private_connection_resource_id = data.azurerm_cosmosdb_account.cosmongo_cargoeslogistics.id
    subresource_names              = ["MongoDB"]
    is_manual_connection           = false
  }

  # ip_configuration {
  #   name               = "cdmz-mgmt-fivetran-cargoeslogistics-ipc"
  #   private_ip_address = var.casmosmongo_fv_ip_address
  #   subresource_name   = "MongoDB"
  #   member_name        = "MongoDB"
    
  # }

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

# ################################################################
# Mpowered provides DP World with SaaS to track and manage their B-BBEE status. This involves loading procurement, people and CSI data in the Mpowered system. The system runs B-BBEE calculations and provides the business with detailed gap analysis on how to improve their compliance.
# Mpowered has a staging database that is a clone of all data loaded in the Mpowered system. DP World has been drawing data from this staging database for use in 'BPI-P'.
# ##########################################################

# # Private end point management for external SQL Server - Mpowered { Managed by <gary@mpowered.co.za>}
resource "azurerm_private_endpoint" "AzureSQL_mpowered_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-mpowered-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-mpowered-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_sql"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz_sql-psc"
    private_connection_resource_id = "/subscriptions/ea795dc4-3b8f-4036-a843-90ee683e0d82/resourceGroups/Mpowered-Analytics/providers/Microsoft.Sql/servers/ma-22-dp-world"
    subresource_names              = ["sqlServer"]
    is_manual_connection           = true
    request_message                = "connectivity from CDP DPWORLD Networks"
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-mpowered-ipc"
    private_ip_address = var.mpowered_fv_ip_address
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

# # Private end point management for Zodiac Coud AULAD FT 

resource "azurerm_private_endpoint" "azurepep_zodiac_aulad_ft" {
  name                = "cdmz-mgmt-fivetran-zodiac-aulad-ft"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name
  subnet_id           = data.azurerm_subnet.snet-default.id

  private_service_connection {
    name                              = "zodiac-aulad-ft-privateserviceconnection"
    private_connection_resource_alias = "zodiaccloud_shareinfra_laddtla_privatelinkservice.acedad72-63a4-41b8-a6b1-df98890642f2.francecentral.azure.privatelinkservice"
    is_manual_connection              = true
    request_message                   = "connectivity from 10.220.224.15"
  }
}

## Private end point connection from Zodiac Coud AULAD FT New {UK South}
##/subscriptions/e51d1ace-d18c-435d-a207-da55e05edf63/resourceGroups/RG_LADPROD_APP/providers/Microsoft.Network/privateLinkServices/LADPROD_APP_LADZPDTLA-1_PrivateLinkService

resource "azurerm_private_endpoint" "azurepep_zodiac_aulad_ft_ukSouth" {
  name                = "cdmz-mgmt-fivetran-zodiac-aulad-ft_ukSouth"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name
  subnet_id           = data.azurerm_subnet.snet-default.id

  private_service_connection {
    name                              = "zodiac-aulad-ft-privateserviceconnection-uksouth"
    private_connection_resource_alias = "ladprod_app_ladzpdtla-1_privatelinkservice.91a11be7-b46e-430b-96ed-d6556af6f2aa.uksouth.azure.privatelinkservice"
    is_manual_connection              = true
    request_message                   = "connectivity from 10.220.224.15"
  }
}


## ## Private end point connection from ILA SAP ECC6 server

resource "azurerm_private_endpoint" "azurepep_ila_SAP_ECC6_server" {
  name                = "cdmz-mgmt-azurepep_ila_SAP_ECC6_server"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name
  subnet_id           = data.azurerm_subnet.snet-default.id

  private_service_connection {
    name                              = "azurepep_ila_SAP_ECC6_server_privateserviceconnection"
    private_connection_resource_alias = "pls-eun-repl-sql01.008af31a-595b-4df3-aa53-3e3b0b742f17.northeurope.azure.privatelinkservice"
    is_manual_connection              = true
    request_message                   = "connectivity from 10.220.224.15"
  }
}


# # Private end point management for PostgreSQL single server psql-hoappnew-dr

data "azurerm_postgresql_server" "Azure_hoappnew_dr" {
  name                = "psql-hoappnew-dr"
  resource_group_name = "Rg-Hoapps-Prod"
  provider            = azurerm.DPWorldGlobal
}



resource "azurerm_private_endpoint" "AzurePSQL_Azure_hoappnew_dr_endpoint_pep" {
  name                = "cdmz-mgmt-fivetran-hoappnew-dr-pep"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-mgmt-fivetran-hoappnew-dr-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns_psql"
    private_dns_zone_ids = [ azurerm_private_dns_zone.pdnsz_psql.id ]
  }
  
  private_service_connection {
    name                           = "cdmz-mgmt-fivetran-pdnsz-psql-psc"
    private_connection_resource_id = data.azurerm_postgresql_server.Azure_hoappnew_dr.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-mgmt-fivetran-hoappnew-dr-ipc"
    private_ip_address = var.hoappnew_dr_fv_ip_address
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


#####################################################################
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

#####Data Section for Azure SQL Server {PAAS}##############

data "azurerm_mssql_server" "AzureSQL_PEP_Sub1" {
  for_each            = { for pep in local.msql_peps: pep.key  => pep if pep.subscription == "DryDocks" }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  provider  = azurerm.DryDocks
  }

data "azurerm_mssql_server" "AzureSQL_PEP_Sub2" {
  for_each            = { for pep in local.msql_peps: pep.key  => pep if pep.subscription == "POEMS" }
  name                = each.value.name
  resource_group_name = each.value.resource_group_name
  provider  = azurerm.POEMS
  }
####Private Endpoints for Azure SQL Server {PAAS}##############

resource "azurerm_private_endpoint" "endpoint" {
    for_each                        = { for pep in local.msql_peps: pep.key => pep }
    name                            = join("-", ["cdmz", each.value.pepsql, each.value.pep_code, "pep"])  
    resource_group_name             = local.networking_resource_group_name
    location                        = var.resource_location

    subnet_id                       = data.azurerm_subnet.snet-default.id

    custom_network_interface_name   = join("-", ["cdmz", each.value.pepsql, each.value.pep_code, "nic"])  

    private_dns_zone_group {
      name = "add_to_azure_private_dns"
      private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
    }

    private_service_connection {
        name                            = join("-", ["cdmz", each.value.pepsql, each.value.pep_code, "psc"])
        private_connection_resource_id  = each.value.subscription == "DryDocks" ? data.azurerm_mssql_server.AzureSQL_PEP_Sub1[each.key].id : data.azurerm_mssql_server.AzureSQL_PEP_Sub2[each.key].id
        subresource_names               = [each.value.pep_code]
        is_manual_connection            = false
        }

    ip_configuration {
        name                =   join("-", ["cdmz", each.value.pepsql, "dls", each.value.pep_code, "ipc"])
        private_ip_address  =   each.value.pep_ip
        subresource_name    =   each.value.pep_code
        member_name         =   each.value.pep_code
    }

    tags    = merge(
      var.resource_tags_spec
    )

    lifecycle {
        ignore_changes  = [
            subnet_id
        ]
    }

    depends_on = [
	  data.azurerm_private_dns_zone.pdnsz_sql
    ]
}
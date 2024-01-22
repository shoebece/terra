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
      name                    = "firewall"
      address_prefix          = "0.0.0.0/0"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.firewall_ip_address
    },
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
      name                    = "Route_P81_SanAntonio_FiveTran_2"
      address_prefix          = "10.11.40.32/32"
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
      name                    = "Route_P81_SanAntonio_FiveTran_5"
      address_prefix          = "10.11.23.62/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_Constanta_Fivetran"
      address_prefix          = "192.168.24.44/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.vpn_firewall_ip_address
    },
    {
      name                    = "Route_P81_Canada_FiveTran_1"
      address_prefix          = "10.41.1.157/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Canada_FiveTran_2"
      address_prefix          = "10.41.2.77/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
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
      name                    = "Route_P81_Caucedo_DR_FiveTran"
      address_prefix          = "192.168.6.44/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_1"
      address_prefix          = "10.1.100.56/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_2"
      address_prefix          = "10.1.6.168/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_3"
      address_prefix          = "10.1.6.169/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
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
data "azurerm_resource_group" "resgrp" {
  name      = "cdmz-networking-rg"
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

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.vaultcore.azure.net"
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

resource "azurerm_virtual_network_peering" "hub_peer" {
  name                      = "peer-hub-to-cdp-management"
  resource_group_name       = data.azurerm_resource_group.resgrp.name
  virtual_network_name      = module.vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
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
data "azurerm_resource_group" "resgrp" {
  name      = join("-", ["cdpz", var.environment, "networking-rg"])
}

resource "azurerm_network_watcher" "netw" {
  count = var.deploy_network_watcher ? 1 : 0

  name = join("-", ["cdpz", var.environment, "nwwatcher", var.resource_location])

  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.resgrp.name

  tags = merge(var.resource_tags_common, var.resource_tags_spec)

  depends_on = [
    data.azurerm_resource_group.resgrp
  ]
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

module "acc_vnet" {
  #count    = (var.environment == "prod" ? 1 : 0)
  source   = "../../../modules/network"

  resource_group_name = data.azurerm_resource_group.resgrp.name
  resource_location   = var.resource_location
  resource_tags       = merge(var.resource_tags_common, var.resource_tags_spec)

  vnet_name                   = join("-", ["cdpz", var.environment, "access-vnet"])
  nsg_name                    = join("-", ["cdpz", var.environment, "access-nsg"])
  vnet_purpose                = "access"
  vnet_address_space          = var.acc_vnet_address_space
  default_snet_address_space  = var.acc_default_snet_address_space
  private_snet_address_space  = var.acc_private_snet_address_space
  public_snet_address_space   = var.acc_public_snet_address_space

  pdnsz_names             = var.pdnsz_names

  depends_on = [
    data.azurerm_resource_group.resgrp,
    azurerm_private_dns_zone.dnss
  ]
}

module "proc_vnet" {
  source   = "../../../modules/network"

  resource_group_name = data.azurerm_resource_group.resgrp.name
  resource_location   = var.resource_location
  resource_tags       = merge(var.resource_tags_common, var.resource_tags_spec)

  vnet_name                   = join("-", ["cdpz", var.environment, "processing-vnet"])
  nsg_name                    = join("-", ["cdpz", var.environment, "processing-nsg"])
  vnet_purpose                = "processing"
  vnet_address_space          = var.proc_vnet_address_space
  default_snet_address_space  = var.proc_default_snet_address_space
  private_snet_address_space  = var.proc_private_snet_address_space
  public_snet_address_space   = var.proc_public_snet_address_space

  pdnsz_names                 = var.pdnsz_names

  depends_on = [
    data.azurerm_resource_group.resgrp,
    azurerm_private_dns_zone.dnss
  ]
}

data "azurerm_subnet" "route-table-snet" {
  count                 = length(var.route_table_snets)

  resource_group_name   = var.route_table_snets[count.index].rgname
  virtual_network_name  = var.route_table_snets[count.index].vnet
  name                  = var.route_table_snets[count.index].snet

  depends_on = [
    module.acc_vnet,
    module.proc_vnet
  ]
}

resource "azurerm_route_table" "art" {
  name                          = join("-", ["cdpz", var.environment, "networking-rt"])
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
      name                    = "Route_P81_Syncreon_FiveTran_2"
      address_prefix          = "10.1.6.168/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_1"
      address_prefix          = "10.1.6.169/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_DPWPLUS_CDP_Synapse"
      address_prefix          = "10.2.0.0/28"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.eur-checkpoint-intfw
    },
    {
      name                    = "Route_P81_Caucedo_DataStream_1"
      address_prefix          = "192.168.6.47/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    # {
    #   name                    = "Route_P81_Caucedo_portsterms_evh01"
    #   address_prefix          = "10.193.1.47/32"
    #   next_hop_type           = "VirtualAppliance"
    #   next_hop_in_ip_address  = var.uae-smart-vpn-firewall_ip_address
    # },
    {
      name                    = "Route_P81_LV_FiveTran_2"
      address_prefix          = "10.1.6.0/24"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod-02
    },
    {
      name                    = "Route_P81_Dublin_qlik_1"
      address_prefix          = "10.16.248.177/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Dublin_qlik_2"
      address_prefix          = "10.16.248.180/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Dublin_qlik_3"
      address_prefix          = "10.16.249.102/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_9"
      address_prefix          = "172.22.0.165/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "ADLS_Canon_Dublin_2"
      address_prefix          = "172.22.0.58/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "ADLS_Canon_Dublin_1"
      address_prefix          = "172.22.0.59/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_10"
      address_prefix          = "172.22.1.121/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_4"
      address_prefix          = "172.22.1.16/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_6"
      address_prefix          = "172.22.2.14/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_5"
      address_prefix          = "172.22.2.75/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_8"
      address_prefix          = "172.22.3.104/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_11"
      address_prefix          = "172.22.3.119/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_12"
      address_prefix          = "172.22.3.129/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod
    },
    {
      name                    = "Route_P81_LV_FiveTran_3"
      address_prefix          = "10.1.0.0/25"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod-02
    },
    {
      name                    = "Route_P81_LV_FiveTran_4"
      address_prefix          = "10.1.1.8/29"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod-02
    },
    {
      name                    = "Route_P81_LV_FiveTran_1"
      address_prefix          = "10.1.4.0/25"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod-02
    },
    {
      name                    = "Route_P81_Syncreon_FiveTran_3"
      address_prefix          = "10.1.6.52/32"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.uae-cpperimeter81-prod-02
    },
    {
      name                    = "Route_vnet-avd-amr-prod"
      address_prefix          = "10.12.0.0/27"
      next_hop_type           = "VirtualAppliance"
      next_hop_in_ip_address  = var.eur-checkpoint-intfw
    },
    {
      name                    = "Route_BIGID"
      address_prefix          = "10.48.16.0/23"
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
  virtual_network_name  = module.proc_vnet.vnet_name
  name                  = "processing-default-snet"

  depends_on = [ module.proc_vnet ]
}

data "azurerm_key_vault" "kv" {
  count               = length(var.key_vault_pep)      
  name                = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].kv_code, "kv"])
  resource_group_name = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].rg_code, "rg"])
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name

  depends_on = [ azurerm_private_dns_zone.dnss ]
}

# Private end point management key vault
resource "azurerm_private_endpoint" "kv_endpoint" {
  count               = length(var.key_vault_pep)

  name                = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].kv_code, "kv-pep"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].kv_code, "kv-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                           = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].kv_code, "kv-psc"])
    private_connection_resource_id = data.azurerm_key_vault.kv[count.index].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = join("-", ["cdpz", var.environment, var.key_vault_pep[count.index].kv_code, "kv-ipc"])
    private_ip_address = var.key_vault_pep[count.index].ip
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
  name = join("-", ["peer-hub-to-cdp", var.environment, "processing"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  virtual_network_name = module.proc_vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
  allow_forwarded_traffic = "true"
}

resource "azurerm_virtual_network_peering" "hub_peer_access" {
  #count    = (var.environment == "prod" ? 1 : 0)
  name = join("-", ["peer-hub-to-cdp", var.environment, "access"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  virtual_network_name = module.acc_vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
  allow_forwarded_traffic = "true"
}

resource "azurerm_virtual_network_peering" "eur_hub_peer" {
  name = join("-", ["peer-eur-hub-to-cdp", var.environment, "processing"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  virtual_network_name = module.proc_vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1b37d994-cdaf-4d33-b73d-afb406d36357/resourceGroups/rg-eur-sechub/providers/Microsoft.Network/virtualNetworks/EUR-Vnetsechub"     
  allow_forwarded_traffic = "true"
}

resource "azurerm_virtual_network_peering" "uae_smart_hub_peer" {
  name = join("-", ["peer-uae-smart-hub-to-cdp", var.environment, "processing"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  virtual_network_name = module.proc_vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/113fbeb3-ce3b-4e2a-b3fd-f9176ff893f3/resourceGroups/rg-dpw-uae-smart-ssh/providers/Microsoft.Network/virtualNetworks/vnet-dpw-uae-smart-ssh"     
  allow_forwarded_traffic = "true"
}
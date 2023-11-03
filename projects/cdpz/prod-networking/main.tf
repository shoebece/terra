data "azurerm_resource_group" "resgrp" {
  name      = join("-", ["cdpz", var.environment, "networking-rg"])
}

# Creted in common networking project - to avoid recreation
# module "acc_vnet" {
#   source   = "../../../modules/network"

#   resource_group_name = data.azurerm_resource_group.resgrp.name
#   resource_location   = var.resource_location
#   resource_tags       = merge(var.resource_tags_common, var.resource_tags_spec)

#   vnet_name                   = "cdpz-prod-access-vnet"
#   nsg_name                    = "cdpz-prod-access-nsg"
#   vnet_purpose                = "access"
#   vnet_address_space          = var.acc_vnet_address_space
#   default_snet_address_space  = var.acc_default_snet_address_space
#   private_snet_address_space  = var.acc_private_snet_address_space
#   public_snet_address_space   = var.acc_public_snet_address_space

#   pdnsz_names             = var.pdnsz_names
# }

module "proc_vnet" {
  source   = "../../../modules/network"

  resource_group_name = data.azurerm_resource_group.resgrp.name
  resource_location   = var.resource_location
  resource_tags       = merge(var.resource_tags_common, var.resource_tags_spec)

  vnet_name                   = "cdpz-global-processing-vnet"
  nsg_name                    = "cdpz-global-processing-nsg"
  vnet_purpose                = "processing"
  vnet_address_space          = var.proc_vnet_address_space
  default_snet_address_space  = var.proc_default_snet_address_space
  private_snet_address_space  = var.proc_private_snet_address_space
  public_snet_address_space   = var.proc_public_snet_address_space

  pdnsz_names                 = var.pdnsz_names
}

data "azurerm_subnet" "route-table-snet" {
  count                 = length(var.route_table_snets)

  resource_group_name   = var.route_table_snets[count.index].rgname
  virtual_network_name  = var.route_table_snets[count.index].vnet
  name                  = var.route_table_snets[count.index].snet

  depends_on = [
    #module.acc_vnet,
    module.proc_vnet
  ]
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

resource "azurerm_subnet_route_table_association" "rt-snets-ass" {
  count           = length(data.azurerm_subnet.route-table-snet)

  subnet_id       = data.azurerm_subnet.route-table-snet[count.index].id
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
  name                = join("-", ["cdpz", var.key_vault_pep[count.index].kv_code, "kv"])
  resource_group_name = join("-", ["cdpz", var.key_vault_pep[count.index].rg_code, "rg"])
}

data "azurerm_private_dns_zone" "pdnsz" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = data.azurerm_resource_group.resgrp.name
}

# Private end point management key vault
resource "azurerm_private_endpoint" "kv_endpoint" {
  count               = length(var.key_vault_pep)

  name                = join("-", ["cdpz", var.key_vault_pep[count.index].kv_code, "kv-pep"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = join("-", ["cdpz", var.key_vault_pep[count.index].kv_code, "kv-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz.id ]
  }

  private_service_connection {
    name                           = join("-", ["cdpz", var.key_vault_pep[count.index].kv_code, "kv-psc"])
    private_connection_resource_id = data.azurerm_key_vault.kv[count.index].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = join("-", ["cdpz", var.key_vault_pep[count.index].kv_code, "kv-ipc"])
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
  name = "peer-hub-to-cdp-global-processing"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  virtual_network_name = module.proc_vnet.vnet_name
  remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
  allow_forwarded_traffic = "true"
}

# resource "azurerm_virtual_network_peering" "hub_peer_access" {
#   name = "peer-hub-to-cdp-prod-access"
#   resource_group_name = data.azurerm_resource_group.resgrp.name
#   virtual_network_name = module.acc_vnet.vnet_name
#   remote_virtual_network_id = "/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam"     
#   allow_forwarded_traffic = "true"
# }
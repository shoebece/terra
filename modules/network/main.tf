# vnet
# prefix = cdmz/cdpz
# purpose = access/processing/management
# --------------------------------------------------------------------------------------------
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  address_space = var.vnet_address_space

  tags = var.resource_tags
}

# network_security_group
# --------------------------------------------------------------------------------------------
resource "azurerm_network_security_group" "nsgs" {
  name                = var.nsg_name
  location            = var.resource_location
  resource_group_name = var.resource_group_name

  tags = var.resource_tags
}

# network_security_rules
# --------------------------------------------------------------------------------------------
resource "azurerm_network_security_rule" "nsgs-secrules" {
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsgs.name

  name                       = "CDP_Deny_Internet_OutBound"
  priority                   = 200
  direction                  = "Outbound"
  access                     = "Deny"
  protocol                   = "*"
  source_port_range          = "*"
  destination_port_range     = "*"
  source_address_prefix      = "Internet"
  destination_address_prefix = "*"

  depends_on = [
    azurerm_network_security_group.nsgs
  ]
}

# default snet
# --------------------------------------------------------------------------------------------
resource "azurerm_subnet" "default_snet" {
  name             = join("-", [var.vnet_purpose, "default-snet"])
  address_prefixes = var.default_snet_address_space

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet_network_security_group_association" "default-snets-nsgs-assoc" {
    subnet_id                 = azurerm_subnet.default_snet.id
    network_security_group_id = azurerm_network_security_group.nsgs.id

    depends_on = [
        azurerm_subnet.default_snet,
        azurerm_network_security_group.nsgs
    ]
}

# private snet
# --------------------------------------------------------------------------------------------
resource "azurerm_subnet" "private-snet" {
  name              = join("-", [var.vnet_purpose, "dbw-private-snet"])
  address_prefixes  = var.private_snet_address_space

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name =  "workspace-delegation-host"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet_network_security_group_association" "private-snet-nsgs-assoc" {
    subnet_id                 = azurerm_subnet.private-snet.id
    network_security_group_id = azurerm_network_security_group.nsgs.id

    depends_on = [
        azurerm_subnet.private-snet,
        azurerm_network_security_group.nsgs
    ]
}

# public snet
# --------------------------------------------------------------------------------------------
resource "azurerm_subnet" "public-snet" {
  name              = join("-", [var.vnet_purpose, "dbw-public-snet"])
  address_prefixes  = var.public_snet_address_space

  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name

  service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]

  delegation {
    name =  "workspace-delegation-host"
    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action"
      ]
    }
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}
resource "azurerm_subnet_network_security_group_association" "public-snet-nsgs-assoc" {
    subnet_id                 = azurerm_subnet.public-snet.id
    network_security_group_id = azurerm_network_security_group.nsgs.id

    depends_on = [
        azurerm_subnet.public-snet,
        azurerm_network_security_group.nsgs
    ]
}

# private_dns_zone_virtual_network_link
# --------------------------------------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "dnss-vnet-link" {
  for_each            = toset(var.pdnsz_names)
  name                    = substr(format("link%s%s%s"
                              ,replace(each.key, "-", "")
                              ,replace(var.resource_group_name, "-", "")
                              ,replace(azurerm_virtual_network.vnet.name, "-", "")), 0, 80)
  resource_group_name     = var.resource_group_name
  private_dns_zone_name   = each.key
  virtual_network_id      = azurerm_virtual_network.vnet.id

  tags                    = var.resource_tags

  lifecycle {
      ignore_changes  = [
          tags,
          virtual_network_id
      ]
  }

  depends_on = [
    azurerm_virtual_network.vnet
  ]
}

output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  value = azurerm_virtual_network.vnet.id
}
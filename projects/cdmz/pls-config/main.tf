locals {# to trzeva przeniesc do var
  resource_group_name             = "cdmz-adf-vnet-ir-pls-rg"
  vnet_name                       = "cdmz-management-vnet"
  snet_name                       = "management-default-snet"
  networking_resource_group_name  = "cdmz-networking-rg"
}

data "azurerm_resource_group" "adf-vnet-ir-pls-rg" {
  name = local.resource_group_name
}

data "azurerm_resource_group" "network-rg" {
  name = local.networking_resource_group_name
}

data "azurerm_subnet" "snet-management-default" {
  name                  = local.snet_name
  resource_group_name   = local.networking_resource_group_name
  virtual_network_name  = local.vnet_name
}

# Standard Load Balancer
resource "azurerm_lb" "example" {
  name                = "example-lb"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.adf-vnet-ir-pls-rg
  sku                 = "Standard"
}

# Load Balancer Frontend IP Configuration
resource "azurerm_lb_frontend_ip_configuration" "example" {
  name                 = "example-frontend-ip"
  loadbalancer_id      = azurerm_lb.example.id
  subnet_id            = azurerm_subnet.private_link.id # Private subnet for PLS
  private_ip_address_allocation = "Dynamic"
}

# Backend Address Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "example" {
  name                 = "example-backend-pool"
  loadbalancer_id      = azurerm_lb.example.id
}

# Health Probe for Load Balancer
resource "azurerm_lb_probe" "example" {
  name                = "example-health-probe"
  loadbalancer_id     = azurerm_lb.example.id
  protocol            = "Tcp"
  port                = 80
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule
resource "azurerm_lb_rule" "example" {
  name                           = "example-lb-rule"
  loadbalancer_id                = azurerm_lb.example.id
  frontend_ip_configuration_name = azurerm_lb_frontend_ip_configuration.example.name
  backend_address_pool_id        = azurerm_lb_backend_address_pool.example.id
  probe_id                       = azurerm_lb_probe.example.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
}

# Private Link Service
resource "azurerm_private_link_service" "example" {
  name                           = "example-pls"
  location                       = azurerm_resource_group.example.location
  resource_group_name            = azurerm_resource_group.example.name
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb_frontend_ip_configuration.example.id]
  subnet_id                      = azurerm_subnet.private_link.id
  auto_approval_subscriptions    = [] # Add subscription IDs for auto-approval
  visibility_subscriptions       = [] # Add subscription IDs for visibility
  nat_ip_configuration {
    name                          = "example-nat-ip"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.private_link.id
  }
}
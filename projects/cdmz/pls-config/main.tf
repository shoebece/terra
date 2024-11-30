locals {# to trzeva przeniesc do var
  resource_group_name             = "cdmz-adf-vnet-ir-pls-rg"
  vnet_name                       = "cdmz-management-vnet"
  snet_name                       = "management-default-snet"
  networking_resource_group_name  = "cdmz-networking-rg"
}

data "azurerm_virtual_machine" "cdmz-adf-ir-nat-01-vm" {
  name                = "cdmz-adf-ir-nat-01-vm"
  resource_group_name = "cdmz-fivetran-integration-rg"
}

data "azurerm_network_interface" "cdmz-adf-ir-nat-01-nic" {
  name                = "adf-ir-nat-01-vm-nic"
  resource_group_name = local.networking_resource_group_name
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
resource "azurerm_lb" "pls-standard-lb" {
  name                = "cdpz-adf-vnet-ir-lb"
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.adf-vnet-ir-pls-rg.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name = "cdpz-adf-vnet-ir-frontend-ip"
    subnet_id = data.azurerm_subnet.snet-management-default.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Load Balancer Frontend IP Configuration
# resource "azurerm_lb_frontend_ip_configuration" "cdpz-adf-vnet-ir-ip" {
#   name                 = "cdpz-adf-vnet-ir-frontend-ip"
#   loadbalancer_id      = azurerm_lb.pls-standard-lb.id
#   subnet_id            = data.azurerm_subnet.snet-management-default.id # Private subnet for PLS
#   private_ip_address_allocation = "Dynamic"
# }

# Backend Address Pool for Load Balancer
resource "azurerm_lb_backend_address_pool" "cdpz-adf-vnet-ir-lb-pool" {
  name                 = "cdpz-adf-vnet-ir-backend-pool"
  loadbalancer_id      = azurerm_lb.pls-standard-lb.id
}

# Health Probe for Load Balancer
resource "azurerm_lb_probe" "cdpz-adf-vnet-ir-lb-probe" {
  name                = "cdpz-adf-vnet-ir-health-probe"
  loadbalancer_id     = azurerm_lb.pls-standard-lb.id
  protocol            = "Tcp"
  port                = 22
  interval_in_seconds = 5
  number_of_probes    = 2
}

# Load Balancer Rule
resource "azurerm_lb_rule" "cdpz-adf-vnet-ir-lb-rule" {
  name                           = "cdpz-adf-vnet-ir-lb-rule"
  loadbalancer_id                = azurerm_lb.pls-standard-lb.id
  frontend_ip_configuration_name = "cdpz-adf-vnet-ir-frontend-ip"
  probe_id                       = azurerm_lb_probe.cdpz-adf-vnet-ir-lb-probe.id
  protocol                       = "Tcp"
  frontend_port                  = 1433
  backend_port                   = 1433
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.cdpz-adf-vnet-ir-lb-pool.id]
}

# Associate Network Interface to the Backend Pool of the Load Balancer
resource "azurerm_network_interface_backend_address_pool_association" "cdpz-adf-vnet-ir-lb-pool-ass" {
  network_interface_id = data.azurerm_network_interface.cdmz-adf-ir-nat-01-nic.id
  ip_configuration_name = "adf-ir-nat-01-vm-ipc"
  backend_address_pool_id = azurerm_lb_backend_address_pool.cdpz-adf-vnet-ir-lb-pool.id
}

# Private Link Service
resource "azurerm_private_link_service" "cdpz-adf-vnet-ir-pls" {
  name                           = "cdpz-adf-vnet-ir-pls"
  location                       = var.resource_location
  resource_group_name            = data.azurerm_resource_group.adf-vnet-ir-pls-rg.name
  load_balancer_frontend_ip_configuration_ids = [azurerm_lb.pls-standard-lb.frontend_ip_configuration[0].id]
  
#   subnet_id                      = data.azurerm_subnet.snet-management-default.id
  auto_approval_subscription_ids              = ["7fafdbc0-65a3-4508-a1da-2bbbdbc2299b"]
  visibility_subscription_ids                 = ["7fafdbc0-65a3-4508-a1da-2bbbdbc2299b"]
  nat_ip_configuration {
    name                          = "cdpz-adf-vnet-ir-nat-ip"
    private_ip_address            = "10.220.224.65"
    private_ip_address_version    = "IPv4"
    subnet_id                     = data.azurerm_subnet.snet-management-default.id
    primary                       = true
  }
}
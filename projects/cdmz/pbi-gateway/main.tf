data "azurerm_resource_group" "pbi-gateway-rg" {
  name = var.resource_group_name
}

data "azurerm_subnet" "snet-management-default" {
  name                  = var.snet_name
  resource_group_name   = var.networking_resource_group_name
  virtual_network_name  = var.vnet_name
}

resource "azurerm_network_interface" "pbi-gateway-nic" {
  count               = length(var.vms)
  name                = join("-", ["cdmz-pbi-gateway", var.vms[count.index].vm, "nic"])
  resource_group_name = var.networking_resource_group_name
  location            = var.resource_location

  ip_configuration {
    name                          = join("-", ["cdmz-pbi-gateway", var.vms[count.index].vm, "ipc"])
    subnet_id                     = data.azurerm_subnet.snet-management-default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vms[count.index].ip
  }

  depends_on = [
    data.azurerm_subnet.snet-management-default
  ]

}

resource "azurerm_windows_virtual_machine" "pbi-gateway-vm" {
  count               = length(var.vms)
  name                = join("-", ["cdmz-pbi-gateway", var.vms[count.index].vm])
  resource_group_name = data.azurerm_resource_group.pbi-gateway-rg.name
  location            = var.resource_location
  size                = "Standard_DS1_v2"
  computer_name       = var.vms[count.index].computer_name
  admin_username      = var.vms[count.index].admin_username
  admin_password      = var.vms[count.index].admin_password

  #encryption_at_host_enabled = ?

  network_interface_ids = [
    azurerm_network_interface.pbi-gateway-nic[count.index].id
  ]

  os_disk {
    name                 = join("-", ["cdmz-pbi-gateway", var.vms[count.index].vm, "osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  identity {
    type = "SystemAssigned"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  depends_on = [
    data.azurerm_resource_group.pbi-gateway-rg,
    azurerm_network_interface.pbi-gateway-nic
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "pbi-vm-autoshdt" {
    count = length(var.vms)
    virtual_machine_id = azurerm_windows_virtual_machine.pbi-gateway-vm[count.index].id
    location = var.resource_location
    enabled = true
    daily_recurrence_time = "1200"
    timezone = "Central Europe Standard Time"
    notification_settings {
      enabled = false
    }  
}

resource "azurerm_role_assignment" "tmp_dev" {
  scope                = data.azurerm_resource_group.pbi-gateway-rg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = "3ba94197-51a7-4ee2-a2bf-6fd4badf0ded"
}
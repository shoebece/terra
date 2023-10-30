locals {# to trzeva przeniesc do var
  resource_group_name             = "cdmz-shared-shir-rg"
  data_factory_name               = "cdmz-shared-shir-adf"
  resource_umid_name              = "cdmz-shared-shir-adf-id"
  vnet_name                       = "cdmz-management-vnet"
  snet_name                       = "management-default-snet"
  networking_resource_group_name  = "cdmz-networking-rg"
}

data "azurerm_resource_group" "shared-shir-rg" {
  name = local.resource_group_name
}

data "azurerm_subnet" "snet-management-default" {
  name                  = local.snet_name
  resource_group_name   = local.networking_resource_group_name
  virtual_network_name  = local.vnet_name
}

resource "azurerm_user_assigned_identity" "umid" {
  name                = local.resource_umid_name
  location            = var.resource_location
  resource_group_name = local.resource_group_name
  tags                = var.resource_tags_common
  
  depends_on          = [data.azurerm_resource_group.shared-shir-rg]
}

resource "azurerm_data_factory" "adf-shir" {
  name                    = local.data_factory_name
  resource_group_name     = local.resource_group_name
  location                = var.resource_location
  tags                    = var.resource_tags_common
  public_network_enabled  = "false"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umid.id]
  }

  dynamic "vsts_configuration" {
    for_each = var.git_integration == true ? [1] : []

    content {
      account_name    = var.git_account_name
      branch_name     = var.git_branch_name
      project_name    = var.git_project_name
      repository_name = var.git_repository_name
      root_folder     = var.git_root_folder
      tenant_id       = var.git_tenant_id
    }
  }

  depends_on = [azurerm_user_assigned_identity.umid]
}

data "azurerm_private_dns_zone" "pdnsz_datafactory" {
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_adf" {
  name                = "cdmz-adf-shir-pep"
  resource_group_name = local.networking_resource_group_name #?
  location            = var.resource_location
  subnet_id           = data.azurerm_subnet.snet-management-default.id
  tags                = var.resource_tags_common
  custom_network_interface_name = "cdmz-adf-shir-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_datafactory.id ]
  } 

  private_service_connection {
    name                            = "cdmz-adf-shir-psc"
    private_connection_resource_id  = azurerm_data_factory.adf-shir.id
    subresource_names               = ["dataFactory"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                = "cdmz-adf-shir-ipc"
    private_ip_address  = var.private_endpoint_ip_address
    subresource_name    = "dataFactory"
    member_name         = "dataFactory"
    
  }

  lifecycle {
    ignore_changes = [ 
      subnet_id
     ]
  }

  depends_on = [ 
    azurerm_data_factory.adf-shir,
    data.azurerm_subnet.snet-management-default,
    data.azurerm_private_dns_zone.pdnsz_datafactory
  ]
}

data "azurerm_private_dns_zone" "pdnsz_adf" {
  name                = "privatelink.adf.azure.com"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_portal" {
  name                = "cdmz-adf-shir-portal-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location
  subnet_id           = data.azurerm_subnet.snet-management-default.id
  tags                = var.resource_tags_common
  custom_network_interface_name = "cdmz-adf-shir-portal-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_adf.id ]
  } 

  private_service_connection {
    name                            = "cdmz-adf-shir-portal-psc"
    private_connection_resource_id  = azurerm_data_factory.adf-shir.id
    subresource_names               = ["portal"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                = "cdmz-adf-shir-portal-ipc"
    private_ip_address  = var.portal_private_endpoint_ip_address
    subresource_name    = "portal"
    member_name         = "portal"
    
  }

  lifecycle {
    ignore_changes = [ 
      subnet_id
     ]
  }

  depends_on = [ 
    azurerm_data_factory.adf-shir,
    data.azurerm_subnet.snet-management-default,
    data.azurerm_private_dns_zone.pdnsz_adf
  ]
}

resource "azurerm_network_interface" "adf-shir-nic" {
  count               = length(var.vms)
  name                = join("-",[var.vms[count.index].vm, "nic"])
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  ip_configuration {
    name                          = join("-",[var.vms[count.index].vm, "ipc"])
    subnet_id                     = data.azurerm_subnet.snet-management-default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vms[count.index].ip
  }

  depends_on = [ 
    data.azurerm_subnet.snet-management-default
   ]
  
}

resource "azurerm_windows_virtual_machine" "shir-vm" {
  count               = length(var.vms)
  name                = var.vms[count.index].vm
  resource_group_name = data.azurerm_resource_group.shared-shir-rg.name
  location            = var.resource_location
  size                = "Standard_DS1_v2"
  computer_name       = var.vms[count.index].computer_name
  admin_username      = var.vms[count.index].admin_username
  admin_password      = var.vms[count.index].admin_password

  #encryption_at_host_enabled = ?

  network_interface_ids = [
    azurerm_network_interface.adf-shir-nic[count.index].id
    ]

  os_disk {
    name                  = join("-",[var.vms[count.index].vm, "osdisk"])
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
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
    data.azurerm_resource_group.shared-shir-rg,
    azurerm_network_interface.adf-shir-nic
    #join("-",["cdmz-adf-shir", var.vms[count.index].vm, "nic"])
    ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "shared-shir-vm-autoshdt" {
    count = length(var.vms)
    virtual_machine_id = azurerm_windows_virtual_machine.shir-vm[count.index].id
    location = var.resource_location
    enabled = true
    daily_recurrence_time = "1000"
    timezone = "Central Europe Standard Time"
    notification_settings {
      enabled = false
    }  
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "shared_shir" {
  name            = "ir-cdp-sefhosted"
  data_factory_id = azurerm_data_factory.adf-shir.id

  depends_on      = [ azurerm_data_factory.adf-shir ]
}

# output "shir_key" {
#   value = azurerm_data_factory_integration_runtime_self_hosted.shared_shir.primary_authorization_key
# }

resource "azurerm_role_assignment" "tmp_dev" {
  scope                = data.azurerm_resource_group.shared-shir-rg.id
  role_definition_name = "Data Factory Contributor"
  principal_id         = "3ba94197-51a7-4ee2-a2bf-6fd4badf0ded"
}
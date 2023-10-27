locals {# to trzeva przeniesc do var
  resource_group_name             = "cdmz-fivetran-integration-rg"
  vnet_name                       = "cdmz-management-vnet"
  snet_name                       = "management-default-snet"
  networking_resource_group_name  = "cdmz-networking-rg"
}

data "azurerm_resource_group" "fivetran-integration-rg" {
  name = local.resource_group_name
}

data "azurerm_subnet" "snet-management-default" {
  name                  = local.snet_name
  resource_group_name   = local.networking_resource_group_name
  virtual_network_name  = local.vnet_name
}

resource "azurerm_network_interface" "fivetran-nic" {
  count               = length(var.vms_fivetran)
  name                = join("-", ["cdmz", var.vms_fivetran[count.index].vm, "nic"])
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  ip_configuration {
    name                          = join("-", ["cdmz", var.vms_fivetran[count.index].vm, "ipc"])
    subnet_id                     = data.azurerm_subnet.snet-management-default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.vms_fivetran[count.index].ip
  }

  depends_on = [
    data.azurerm_subnet.snet-management-default
  ]
}

resource "azurerm_windows_virtual_machine" "fivetran-vm" {
  count               = length(var.vms_fivetran)
  name                = join("-", ["cdmz", var.vms_fivetran[count.index].vm])
  resource_group_name = data.azurerm_resource_group.fivetran-integration-rg.name
  location            = var.resource_location
  size                = "Standard_D4s_v3"
  computer_name       = var.vms_fivetran[count.index].computer_name
  admin_username      = var.vms_fivetran[count.index].admin_username
  admin_password      = var.vms_fivetran[count.index].admin_password

  #encryption_at_host_enabled = ?

  network_interface_ids = [
    azurerm_network_interface.fivetran-nic[count.index].id
  ]

  os_disk {
    name                 = join("-", ["cdmz", var.vms_fivetran[count.index].vm, "osdisk"])
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
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
    data.azurerm_resource_group.fivetran-integration-rg
    ,azurerm_network_interface.fivetran-nic
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "fivetran-autoshdt" {
    count = length(var.vms_fivetran)
    virtual_machine_id = azurerm_windows_virtual_machine.fivetran-vm[count.index].id
    location = var.resource_location
    enabled = true
    daily_recurrence_time = "1000"
    timezone = "Central Europe Standard Time"
    notification_settings {
      enabled = false
    }  
}

resource "azurerm_mssql_server" "fivetran_config_sql_srv" {
  name                         = "cdmz-fivetran-conf-db-sql"
  resource_group_name          = data.azurerm_resource_group.fivetran-integration-rg.name
  location                     = var.resource_location
  version                      = "12.0"
  administrator_login          = "dbadmin"
  administrator_login_password = var.admin_pass
  minimum_tls_version          = "1.2"

  azuread_administrator {
    login_username              = var.super_user_aad_group.name
    object_id                   = var.super_user_aad_group.id
    #azuread_authentication_only = "true" ##?
  }
}

resource "azurerm_mssql_database" "fivetran_config_sql_db" {
  name           = "configurationdb"
  server_id      = azurerm_mssql_server.fivetran_config_sql_srv.id
  sku_name       = "S0"

  depends_on = [ azurerm_mssql_server.fivetran_config_sql_srv ]
}

data "azurerm_private_dns_zone" "pdnsz_sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_adf" {
  name                = "cdmz-fivetran-conf-db-sql-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location
  subnet_id           = data.azurerm_subnet.snet-management-default.id
  tags                = var.resource_tags_common
  custom_network_interface_name = "cdmz-fivetran-conf-db-sql-nic"

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_sql.id ]
  }

  private_service_connection {
    name                            = "cdmz-fivetran-conf-db-sql-psc"
    private_connection_resource_id  = azurerm_mssql_server.fivetran_config_sql_srv.id
    subresource_names               = ["sqlServer"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                = "cdmz-fivetran-conf-db-sql-ipc"
    private_ip_address  = var.sql_private_endpoint_ip_address
    subresource_name    = "sqlServer"
    member_name         = "sqlServer"
    
  }

  lifecycle {
    ignore_changes = [ 
      subnet_id
    ]
  }

  depends_on = [ 
    azurerm_mssql_server.fivetran_config_sql_srv,
    data.azurerm_subnet.snet-management-default,
    data.azurerm_private_dns_zone.pdnsz_sql
  ]
}

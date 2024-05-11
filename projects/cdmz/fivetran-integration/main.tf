locals {# to trzeva przeniesc do var
  resource_group_name             = "cdmz-fivetran-integration-rg"
  vnet_name                       = "cdmz-management-vnet"
  snet_name                       = "management-default-snet"
  networking_resource_group_name  = "cdmz-networking-rg"
}

data "azurerm_resource_group" "fivetran-integration-rg" {
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

resource "azurerm_network_interface" "fivetran-nic" {
  for_each            = { for vm in var.vms_fivetran: vm.vm => vm }
  name                = join("-", ["cdmz", each.value.vm, "nic"])
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  ip_configuration {
    name                          = join("-", ["cdmz", each.value.vm, "ipc"])
    subnet_id                     = data.azurerm_subnet.snet-management-default.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.ip
  }

  tags = merge( data.azurerm_resource_group.network-rg.tags, var.resource_tags_spec )

  depends_on = [
    data.azurerm_subnet.snet-management-default
  ]
}

resource "azurerm_windows_virtual_machine" "fivetran-vm" {
  for_each            = { for vm in var.vms_fivetran: vm.vm => vm }
  name                = join("-", ["cdmz", each.value.vm])
  resource_group_name = data.azurerm_resource_group.fivetran-integration-rg.name
  location            = var.resource_location
  size                = each.value.size
  computer_name       = each.value.computer_name
  admin_username      = each.value.admin_username
  admin_password      = var.vm_admin_password
  license_type        = "Windows_Server"
  patch_assessment_mode = "AutomaticByPlatform"
  patch_mode          = "AutomaticByPlatform"

  #encryption_at_host_enabled = ?

  network_interface_ids = [
    azurerm_network_interface.fivetran-nic[each.value.vm].id
  ]

  os_disk {
    name                 = join("-", ["cdmz", each.value.vm, "osdisk"])
    caching              = "ReadWrite"
    storage_account_type = each.value.disk_sku
    disk_size_gb         = each.value.disk_size_gb
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

  tags = merge(var.resource_tags_common, var.resource_tags_spec, var.resource_ospatching_tags_spec)

  lifecycle {
    ignore_changes = [
      admin_password
    ]
  }

  depends_on = [
    data.azurerm_resource_group.fivetran-integration-rg
    ,azurerm_network_interface.fivetran-nic
  ]
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "fivetran-autoshdt" {
    for_each = { for vm in var.vms_fivetran: vm.vm => vm }
    virtual_machine_id = azurerm_windows_virtual_machine.fivetran-vm[each.value.vm].id
    location = var.resource_location
    enabled = false
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
  administrator_login_password = var.sql_admin_password
  minimum_tls_version          = "1.2"
  tags                         = var.resource_tags_common

  azuread_administrator {
    login_username              = var.super_user_aad_group.name
    object_id                   = var.super_user_aad_group.id
    #azuread_authentication_only = "true" ##?
  }
}

resource "azurerm_mssql_elasticpool" "fivetran_config_sql_pool" {
  name                = "cdmz-fivetran-conf-db-sqlpool"
  resource_group_name = azurerm_mssql_server.fivetran_config_sql_srv.resource_group_name
  location            = azurerm_mssql_server.fivetran_config_sql_srv.location
  server_name         = azurerm_mssql_server.fivetran_config_sql_srv.name
  tags                = var.resource_tags_common
  max_size_gb         = 50

  sku {
    name     = "StandardPool"
    tier     = "Standard"
    capacity = 200
  }

  per_database_settings {
    min_capacity = 10
    max_capacity = 20
  }

  depends_on = [azurerm_mssql_server.fivetran_config_sql_srv]
}

resource "azurerm_mssql_database" "fivetran_config_sql_db" {
  for_each  = { for sql in var.fivetran_sql_dbs: sql.name => sql }
  name      = each.value.name
  server_id = azurerm_mssql_server.fivetran_config_sql_srv.id
  elastic_pool_id = azurerm_mssql_elasticpool.fivetran_config_sql_pool.id

  depends_on = [azurerm_mssql_server.fivetran_config_sql_srv, 
  azurerm_mssql_elasticpool.fivetran_config_sql_pool]
}

# resource "azurerm_mssql_database" "fivetran_config_sql_db" {
#   name           = "configurationdb"
#   server_id      = azurerm_mssql_server.fivetran_config_sql_srv.id
#   sku_name       = "S0"

#   depends_on = [ azurerm_mssql_server.fivetran_config_sql_srv ]
# }

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

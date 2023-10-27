locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "networking-rg"])
}

data "azurerm_resource_group" "resgrp" {
  name = join("-", ["cdpz", var.environment, "sharing-rg"])
}

resource "azurerm_user_assigned_identity" "umi" {
  name                = join("-", ["cdpz", var.environment, "sharing-synapse-umi"])
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_storage_account" "synapse_dls" {
  name                     = join("", [var.sandbox_prefix, "cdpz", var.environment, "synapsedls"])
  resource_group_name      = data.azurerm_resource_group.resgrp.name
  location                 = var.resource_location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"

  network_rules {
    default_action              = "Deny"
    virtual_network_subnet_ids  = ["/subscriptions/1691759c-bec8-41b8-a5eb-03c57476ffdb/resourceGroups/rg-infrateam/providers/Microsoft.Network/virtualNetworks/vnet-infrateam/subnets/snet-aks-infra"]
  }
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse_fs" {
  name               = "data"
  storage_account_id = azurerm_storage_account.synapse_dls.id
  depends_on = [ azurerm_storage_account.synapse_dls ]
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = join("-", ["cdpz", var.environment, "sharing-synapse"])
  resource_group_name                  = data.azurerm_resource_group.resgrp.name
  location                             = var.resource_location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse_fs.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = var.admin_pass
  managed_virtual_network_enabled      = true
  managed_resource_group_name          = join("-", ["cdpz", var.environment, "sharing-synapse-mrg"])

  identity {
    type = "SystemAssigned, UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.umi.id]
  }

  # aad_admin {
  #   login     = var.aad_admin_login
  #   object_id = var.aad_admin_object_id
  #   tenant_id = var.tenant_id
  # }

  depends_on = [
    azurerm_storage_data_lake_gen2_filesystem.synapse_fs
    ,azurerm_user_assigned_identity.umi
  ]
}

# resource "azurerm_synapse_role_assignment" "devops_as_admin" {
#   synapse_workspace_id = azurerm_synapse_workspace.synapse.id
#   role_name            = "Synapse Administrator"
#   principal_id         = "511f91ea-3f0b-47d5-9c40-eb1a2f454a91"

#   depends_on = [azurerm_synapse_workspace.synapse]
# }

resource "azurerm_synapse_firewall_rule" "syn_firewall" {
  count                = length(var.allowed_ips)
  name                 = var.allowed_ips[count.index].name
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = var.allowed_ips[count.index].start_ip_address
  end_ip_address       = var.allowed_ips[count.index].end_ip_address

  depends_on = [ azurerm_synapse_workspace.synapse ]
}

# resource "azurerm_synapse_managed_private_endpoint" "fs_pep" {
#   name                  = join("-", ["cdpz", var.environment, "sharing-synapse_mpep"])
#   synapse_workspace_id  = azurerm_synapse_workspace.synapse.id
#   target_resource_id    = azurerm_storage_account.synapse_dls.id
#   subresource_name      = "dfs"

#   depends_on = [ azurerm_synapse_firewall_rule.syn_firewall ]
# }

data "azurerm_storage_account" "serving_stacc" {
  resource_group_name = join("-", ["cdpz", var.environment, "data-storage-rg"])
  name                = join("", ["cdpz", var.environment, "serving01dls"])
}

resource "azurerm_synapse_managed_private_endpoint" "serving_pep" {
  name                  = join("-", ["cdpz", var.environment, "serving01dls_mpep"])
  synapse_workspace_id  = azurerm_synapse_workspace.synapse.id
  target_resource_id    = data.azurerm_storage_account.serving_stacc.id
  subresource_name      = "dfs"

  depends_on = [ 
    azurerm_synapse_firewall_rule.syn_firewall
    ,data.azurerm_storage_account.serving_stacc
    #,azurerm_synapse_role_assignment.devops_as_admin
  ]
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_private_dns_zone" "syn_sql_pdnsz" {
  name                = "privatelink.sql.azuresynapse.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "sql_on-demand_pep" {
  name                            = join("-", ["cdpz", var.environment, "synapse-sql-on-demand-pep"])  
  resource_group_name             = local.networking_resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, "synapse-sql-on-demand-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.syn_sql_pdnsz.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "synapse-sql-on-demand-psc"])
    private_connection_resource_id  = azurerm_synapse_workspace.synapse.id
    subresource_names               = ["SqlOnDemand"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                =   join("-", ["cdpz", var.environment, "synapse-sql-on-demand-ipc"])
    private_ip_address  =   var.synapse_sql_on_demand_pep_ip_address
    subresource_name    =   "SqlOnDemand"
    member_name         =   "SqlOnDemand"
  }

  tags    = merge(
    var.resource_tags_spec
  )

  lifecycle {
      ignore_changes  = [
          subnet_id
      ]
  }

  depends_on = [
    azurerm_synapse_workspace.synapse
    ,data.azurerm_subnet.snet
    ,data.azurerm_private_dns_zone.syn_sql_pdnsz
  ]
}
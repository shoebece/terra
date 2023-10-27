locals {
  networking_resource_group_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

resource "azurerm_storage_account" "data_stacc" {
  name                      = var.stacc_full_name
  resource_group_name       = var.resource_group_name
  location                  = var.resource_location
  account_tier              = "Standard"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
  public_network_access_enabled       = var.public_access_enabled
  allow_nested_items_to_be_public     = false
  min_tls_version           = "TLS1_2"
  is_hns_enabled            = true
  account_kind              = "StorageV2"
  
  identity {
    type = "UserAssigned"
    identity_ids = [ var.stacc_umi_id ]
  }

  network_rules {
    default_action              = "Deny"
    virtual_network_subnet_ids  = var.service_endpoint_snets
  }
  
  tags = var.resource_tags

  lifecycle {
    ignore_changes = [
      customer_managed_key
    ]
  }
}

resource "azurerm_storage_container" "conts" {
  for_each              = toset(var.stacc_containers)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.data_stacc.name
  container_access_type = "private"
}

resource "azurerm_storage_account_customer_managed_key" "stacc_cmk" {
  storage_account_id        = azurerm_storage_account.data_stacc.id
  key_vault_id              = var.cmk_key_vault_id
  key_name                  = var.cmk_key_name
  user_assigned_identity_id = var.stacc_umi_id
}

# Optional
data "azurerm_subnet" "snet" {
  resource_group_name  = join("-", ["cdpz", var.environment, "networking-rg"])
  virtual_network_name = local.networking_resource_group_name
  name                 = "processing-default-snet"
}

resource "azurerm_private_endpoint" "pep" {
  for_each                        = { for i, pep in var.peps: pep => pep }

  name                            = join("-", ["cdpz", var.environment, var.stacc_name, "dls", each.value.code, "pep"])  
  resource_group_name             = data.azurerm_subnet.snet.resource_group_name
  location                        = var.resource_location

  subnet_id                       = data.azurerm_subnet.snet.id

  custom_network_interface_name   = join("-", ["cdpz", var.environment, var.stacc_name, "dls", each.value.code, "nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    #private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_blob.id ]
    private_dns_zone_ids = [ join("", [
      "/subscriptions/", var.subscription_id, 
      "/resourceGroups/", local.networking_resource_group_name, 
      "/providers/Microsoft.Network/privateDnsZones",
      "/privatelink.", each.value.code, ".core.windows.net" ])
    ]
  }  

  private_service_connection {
      name                            = join("-", ["cdpz", var.environment, var.stacc_name, "dls", each.value.code, "psc"])
      private_connection_resource_id  = azurerm_storage_account.data_stacc.id
      subresource_names               = [each.value.code]
      is_manual_connection            = false
      }

  ip_configuration {
      name                =   join("-", ["cdpz", var.environment, var.stacc_name, "dls", each.value.code, "ipc"])
      private_ip_address  =   each.value.ip
      subresource_name    =   each.value.code
      member_name         =   each.value.code
  }

  tags    = var.resource_tags

  lifecycle {
      ignore_changes  = [
          subnet_id
      ]
  }
}

output "name" {
  value = join("", [
      "/subscriptions/", var.subscription_id, 
      "/resourceGroups/", local.networking_resource_group_name, 
      "/providers/Microsoft.Network/privateDnsZones",
      "/privatelink.", "blob", ".core.windows.net" ])
}
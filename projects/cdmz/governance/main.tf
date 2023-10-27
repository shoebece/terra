locals {
  networking_resource_group_name = "cdmz-networking-rg"
}

data "azurerm_resource_group" "resgrp" {
  name     = "cdmz-governance-rg"
}

data "azurerm_subnet" "snet-default" {
  name                 = "management-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = "cdmz-management-vnet"
}

# User Managed idntity for
resource "azurerm_user_assigned_identity" "umi" {
  name                = "cdmz-management-prview-umi"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location
}

resource "azurerm_purview_account" "pview" {
  name                = "cdmz-management-prview"
  resource_group_name = data.azurerm_resource_group.resgrp.name
  location            = var.resource_location

  identity {
    type = "SystemAssigned"#, UserAssigned"
    #identity_ids = [azurerm_user_assigned_identity.umi.id]
  }

  managed_resource_group_name = "cdmz-management-prview-mrg"
  public_network_enabled      = "false"
  tags                        = merge(var.resource_tags_spec, var.resource_tags_common)

  depends_on = [ azurerm_user_assigned_identity.umi ]
}

resource "azurerm_private_endpoint" "endpoint_acc" {
  name                = "cdmz-pview-account-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-pview-account-pep-nic"

  private_service_connection {
    name                           = "cdmz-pview-account-pep-psc"
    private_connection_resource_id = azurerm_purview_account.pview.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-pview-account-pep-ipc"
    private_ip_address = var.purview_account_pep_ip
    subresource_name   = "account"
    member_name        = "account"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id,
      private_dns_zone_group
    ]
  }

  depends_on = [azurerm_purview_account.pview]
}

resource "azurerm_private_endpoint" "endpoint_portal" {
  name                = "cdmz-pview-portal-pep"
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location

  subnet_id = data.azurerm_subnet.snet-default.id

  custom_network_interface_name = "cdmz-pview-portal-pep-nic"

  private_service_connection {
    name                           = "cdmz-pview-portal-pep-psc"
    private_connection_resource_id = azurerm_purview_account.pview.id
    subresource_names              = ["portal"]
    is_manual_connection           = false
  }

  ip_configuration {
    name               = "cdmz-pview-portal-pep-ipc"
    private_ip_address = var.purview_portal_pep_ip
    subresource_name   = "portal"
    member_name        = "portal"
  }

  tags = merge(
    var.resource_tags_spec
  )

  lifecycle {
    ignore_changes = [
      subnet_id,
      private_dns_zone_group
    ]
  }

  depends_on = [azurerm_purview_account.pview]
}
locals {
  resource_group_name             = join("-", ["cdpz", var.environment, "orchestration-and-ingestion-rg"])
  data_factory_name               = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf"])
  resource_umid_name              = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-umi"])
  key_vault_name                  = join("-", ["cdpz", var.environment, "orchestr-kv"])
  networking_resource_group_name  = join("-", ["cdpz", var.environment, "networking-rg"])
}

data "azurerm_resource_group" "orchestration-and-ingestion-rg" {
  name     = local.resource_group_name
}

data "azurerm_key_vault" "orchestration-and-ingestion-kv" {
  name = local.key_vault_name
  resource_group_name = local.resource_group_name  
}

resource "azurerm_user_assigned_identity" "orchestration-and-ingestion-umid" {
  name                = local.resource_umid_name
  location            = var.resource_location
  resource_group_name = data.azurerm_resource_group.orchestration-and-ingestion-rg.name
  tags                = merge( var.resource_tags_common, var.resource_tags_spec)
  
  depends_on          = [data.azurerm_resource_group.orchestration-and-ingestion-rg]
}

resource "azurerm_data_factory" "orchestration-and-ingestion-adf" {
  name                    = local.data_factory_name
  resource_group_name     = local.resource_group_name
  location                = var.resource_location
  tags                    = merge( var.resource_tags_common, var.resource_tags_spec)
  public_network_enabled  = "false"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.orchestration-and-ingestion-umid.id]
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

  depends_on = [azurerm_user_assigned_identity.orchestration-and-ingestion-umid]
}

resource "azurerm_role_assignment" "roleassign" {
  name                 = azurerm_user_assigned_identity.orchestration-and-ingestion-umid.client_id
  scope                = data.azurerm_key_vault.orchestration-and-ingestion-kv.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.orchestration-and-ingestion-umid.principal_id

  depends_on = [azurerm_user_assigned_identity.orchestration-and-ingestion-umid, data.azurerm_key_vault.orchestration-and-ingestion-kv]
}

data "azurerm_subnet" "snet" {
  name                 = "processing-default-snet"
  resource_group_name  = local.networking_resource_group_name
  virtual_network_name = join("-", ["cdpz", var.environment, "processing-vnet"])
}

data "azurerm_private_dns_zone" "pdnsz_datafactory" {
  name                = "privatelink.datafactory.azure.net"
  resource_group_name = local.networking_resource_group_name
}

resource "azurerm_private_endpoint" "endpoint_adf" {
  name                = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-pep"])
  resource_group_name = local.networking_resource_group_name
  location            = var.resource_location
  subnet_id           = data.azurerm_subnet.snet.id
  tags                = var.resource_tags_common
  custom_network_interface_name = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-nic"])

  private_dns_zone_group {
    name = "add_to_azure_private_dns"
    private_dns_zone_ids = [ data.azurerm_private_dns_zone.pdnsz_datafactory.id ]
  }

  private_service_connection {
    name                            = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-psc"])
    private_connection_resource_id  = azurerm_data_factory.orchestration-and-ingestion-adf.id
    subresource_names               = ["dataFactory"]
    is_manual_connection            = false
  }

  ip_configuration {
    name                = join("-", ["cdpz", var.environment, "orchestr-and-ingestion-adf-ipc"])
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
    azurerm_data_factory.orchestration-and-ingestion-adf,
    data.azurerm_subnet.snet,
    data.azurerm_private_dns_zone.pdnsz_datafactory
  ]
}

data "azurerm_data_factory" "cdmz-shared-shir-adf" {
  provider            = azurerm.cdmz
  resource_group_name = "cdmz-shared-shir-rg"
  name                = "cdmz-shared-shir-adf"
}

# Linked ADF UMI is Contributor on Shared ADF
resource "azurerm_role_assignment" "linked-to-shared-adf" {
  scope                = data.azurerm_data_factory.cdmz-shared-shir-adf.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.orchestration-and-ingestion-umid.principal_id
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "shir" {
  name            = "ir-cdp-sefhosted"
  data_factory_id = azurerm_data_factory.orchestration-and-ingestion-adf.id

  rbac_authorization {
    resource_id = var.shared_shir_id
  }

  depends_on = [ azurerm_role_assignment.linked-to-shared-adf ]
}
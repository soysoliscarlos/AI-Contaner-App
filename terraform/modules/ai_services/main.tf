# -----------------------------------------------------------------------------
# AI Services module: Log Analytics, Azure OpenAI, Azure AI Search.
# No RBAC assignments here; those are in workload_identity.
# -----------------------------------------------------------------------------

# Log Analytics for Container Apps Environment and centralised logging.
resource "azurerm_log_analytics_workspace" "workspace" {
  name                = "${var.name_prefix}-law"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# Azure OpenAI: custom_subdomain_name is required for Entra ID (RBAC) authentication.
resource "azurerm_cognitive_account" "openai" {
  name                          = "${var.name_prefix}openai"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.openai_sku
  custom_subdomain_name         = "${var.name_prefix}openai"
  public_network_access_enabled = var.openai_public_network_access_enabled

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_cognitive_deployment" "openai" {
  for_each = { for d in var.openai_deployments : d.name => d }

  name                 = each.key
  cognitive_account_id  = azurerm_cognitive_account.openai.id

  model {
    format  = "OpenAI"
    name    = each.value.model.name
    version = each.value.model.version
  }

  sku {
    name     = "Standard"
    capacity = 10
  }
}

# Azure AI Search: RBAC-only when local_authentication_enabled = false.
resource "azurerm_search_service" "search" {
  name                          = "${var.name_prefix}-search"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = var.search_sku
  replica_count                 = var.search_replica_count
  partition_count               = var.search_partition_count
  local_authentication_enabled  = var.search_local_authentication_enabled
  public_network_access_enabled = true
}

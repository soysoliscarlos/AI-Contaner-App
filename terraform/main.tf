# -----------------------------------------------------------------------------
# Zero-Trust AI infrastructure: Azure OpenAI, AI Search, Container Apps.
# No API keys; all access via Managed Identity and RBAC.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
  # backend "azurerm" { ... }  # opcional
}

provider "azurerm" {
  features {}
}

# Single resource group for all resources.
resource "azurerm_resource_group" "rg" {
  name     = "${var.name_prefix}-rg"
  location = var.location
}

# 1. Network: VNet and subnets (Container Apps + Private Endpoints).
module "network" {
  source = "./modules/network"

  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  name_prefix                  = var.name_prefix
  virtual_network_cidr         = var.virtual_network_cidr
  container_apps_subnet_cidr    = var.container_apps_subnet_cidr
  private_endpoints_subnet_cidr = var.private_endpoints_subnet_cidr
}

# 2. AI services: Log Analytics, Azure OpenAI, Azure AI Search.
module "ai_services" {
  source = "./modules/ai_services"

  resource_group_name             = azurerm_resource_group.rg.name
  location                        = azurerm_resource_group.rg.location
  name_prefix                     = var.name_prefix
  openai_sku                      = var.openai_sku
  openai_deployments              = var.openai_deployments
  openai_public_network_access_enabled = var.openai_public_network_access_enabled
  search_sku                      = var.search_sku
  search_replica_count            = var.search_replica_count
  search_partition_count          = var.search_partition_count
  search_local_authentication_enabled = var.search_local_authentication_enabled
}

# 2b. Azure Container Registry (for container images; aligns with Azure sample).
module "container_registry" {
  source = "./modules/container_registry"

  name                = "${var.name_prefix}acr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.acr_sku
  admin_enabled       = var.acr_admin_enabled
}

# 2c. Private DNS zones and private endpoints (when use_private_endpoints = true).
module "openai_private_dns_zone" {
  source = "./modules/private_dns_zone"
  count  = var.use_private_endpoints ? 1 : 0

  name                = "privatelink.openai.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
}

module "acr_private_dns_zone" {
  source = "./modules/private_dns_zone"
  count  = var.use_private_endpoints ? 1 : 0

  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.rg.name
  vnet_id             = module.network.vnet_id
  vnet_name           = module.network.vnet_name
}

module "openai_private_endpoint" {
  source = "./modules/private_endpoint"
  count  = var.use_private_endpoints ? 1 : 0

  name                         = "${var.name_prefix}openai-pe"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  subnet_id                    = module.network.private_endpoints_subnet_id
  private_connection_resource_id = module.ai_services.openai_id
  subresource_names            = ["account"]
  private_dns_zone_ids         = [module.openai_private_dns_zone[0].id]
  private_dns_zone_group_name  = "openai-dns"
}

module "acr_private_endpoint" {
  source = "./modules/private_endpoint"
  count  = var.use_private_endpoints ? 1 : 0

  name                         = "${var.name_prefix}acr-pe"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  subnet_id                    = module.network.private_endpoints_subnet_id
  private_connection_resource_id = module.container_registry.id
  subresource_names            = ["registry"]
  private_dns_zone_ids         = [module.acr_private_dns_zone[0].id]
  private_dns_zone_group_name  = "acr-dns"
}

# 3. Workload identity: User Assigned MI + RBAC (OpenAI User, Search Index Data Contributor, AcrPull).
module "workload_identity" {
  source = "./modules/workload_identity"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name_prefix         = var.name_prefix
  openai_id           = module.ai_services.openai_id
  search_service_id   = module.ai_services.search_service_id
  acr_id              = module.container_registry.id
}

# 4. Container Apps: Environment (Log Analytics + VNet integration).
module "container_apps" {
  source = "./modules/container_apps"

  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  name_prefix                 = var.name_prefix
  container_apps_subnet_id    = module.network.container_apps_subnet_id
  log_analytics_workspace_id  = module.ai_services.log_analytics_workspace_id
  workload_identity_id        = module.workload_identity.workload_identity_id
  workload_identity_client_id = module.workload_identity.workload_identity_client_id
}

# Las Container Apps se despliegan en un Terraform separado: terraform-container-apps/

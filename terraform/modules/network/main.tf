# -----------------------------------------------------------------------------
# Network module: VNet and subnets for Container Apps and Private Endpoints.
# Container Apps Environment requires a delegated subnet.
# -----------------------------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.name_prefix}-vnet"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = [var.virtual_network_cidr]
}

# Subnet for Azure Container Apps Environment (must be delegated).
resource "azurerm_subnet" "container_apps" {
  name                 = "ContainerApps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.container_apps_subnet_cidr]

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

# Subnet for private endpoints (OpenAI, Search, etc.) when enabling full Zero-Trust.
resource "azurerm_subnet" "private_endpoints" {
  name                 = "PrivateEndpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.private_endpoints_subnet_cidr]
}

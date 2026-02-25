# -----------------------------------------------------------------------------
# Azure Container Registry for container images (aligns with Azure sample).
# Workload identity gets AcrPull so Container Apps can pull without admin.
# -----------------------------------------------------------------------------

resource "azurerm_container_registry" "acr" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
}

# -----------------------------------------------------------------------------
# Container Apps module: Environment only.
# Uses VNet integration and Log Analytics; no Container App in this module.
# Deploy your LangChain/n8n app later and attach workload_identity_id + AZURE_CLIENT_ID.
# -----------------------------------------------------------------------------

resource "azurerm_container_app_environment" "env" {
  name                       = "${var.name_prefix}-ca-env"
  location                   = var.location
  resource_group_name        = var.resource_group_name
  log_analytics_workspace_id = var.log_analytics_workspace_id

  infrastructure_subnet_id = var.container_apps_subnet_id
  internal_load_balancer_enabled = false
}

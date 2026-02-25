# -----------------------------------------------------------------------------
# Root outputs: endpoint URLs and IDs for application configuration.
# All values are derived from modules; no secrets.
# -----------------------------------------------------------------------------

output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL (e.g. https://<name>.openai.azure.com/). Use with DefaultAzureCredential and AZURE_CLIENT_ID."
  value       = module.ai_services.openai_endpoint
}

output "openai_deployment_names" {
  description = "Map of deployment names (e.g. gpt-4o, text-embedding-3-small) for application config."
  value       = module.ai_services.openai_deployment_names
}

output "search_endpoint" {
  description = "Azure AI Search endpoint URL (e.g. https://<name>.search.windows.net)."
  value       = module.ai_services.search_endpoint
}

output "search_name" {
  description = "Azure AI Search service name (for SDK connection with DefaultAzureCredential)."
  value       = module.ai_services.search_name
}

output "container_app_environment_id" {
  description = "ID of the Container Apps Environment (for deploying apps)."
  value       = module.container_apps.container_app_environment_id
}

output "workload_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity. Set as AZURE_CLIENT_ID in the container app."
  value       = module.workload_identity.workload_identity_client_id
}

output "workload_identity_id" {
  description = "Resource ID of the User Assigned Managed Identity (for identity block on Container App)."
  value       = module.workload_identity.workload_identity_id
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace (linked to Container Apps Environment)."
  value       = module.ai_services.log_analytics_workspace_id
}

output "acr_login_server" {
  description = "ACR login server (e.g. <name>.azurecr.io). Use for Container App image source."
  value       = module.container_registry.login_server
}

output "name_prefix" {
  description = "Prefix usado en la infra; usar el mismo en terraform-container-apps para enlazar recursos."
  value       = var.name_prefix
}

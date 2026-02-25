output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace."
  value       = azurerm_log_analytics_workspace.workspace.id
}

output "openai_id" {
  description = "ID of the Azure OpenAI Cognitive Services account."
  value       = azurerm_cognitive_account.openai.id
}

output "openai_endpoint" {
  description = "Azure OpenAI endpoint URL (for application config)."
  value       = azurerm_cognitive_account.openai.endpoint
}

output "openai_deployment_names" {
  description = "Map of deployment names (key = deployment name)."
  value       = { for k, v in azurerm_cognitive_deployment.openai : k => k }
}

output "search_service_id" {
  description = "ID of the Azure AI Search service."
  value       = azurerm_search_service.search.id
}

output "search_endpoint" {
  description = "Azure AI Search endpoint URL."
  value       = "https://${azurerm_search_service.search.name}.search.windows.net"
}

output "search_name" {
  description = "Azure AI Search service name (for SDK with DefaultAzureCredential)."
  value       = azurerm_search_service.search.name
}

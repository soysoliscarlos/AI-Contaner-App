output "container_app_environment_id" {
  description = "ID of the Container Apps Environment (for deploying apps)."
  value       = azurerm_container_app_environment.env.id
}

output "container_app_environment_default_domain" {
  description = "Default domain of the Container Apps Environment."
  value       = azurerm_container_app_environment.env.default_domain
}

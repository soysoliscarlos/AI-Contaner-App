output "id" {
  description = "Resource ID of the Container Registry."
  value       = azurerm_container_registry.acr.id
}

output "name" {
  description = "Name of the Container Registry."
  value       = azurerm_container_registry.acr.name
}

output "login_server" {
  description = "Login server URL (e.g. <name>.azurecr.io)."
  value       = azurerm_container_registry.acr.login_server
}

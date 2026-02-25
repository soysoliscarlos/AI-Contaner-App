output "container_app_fqdn" {
  description = "FQDN of the latest revision of each Container App."
  value       = { for n, app in azurerm_container_app.app : n => "https://${app.latest_revision_fqdn}" }
}

output "container_app_ids" {
  description = "Resource IDs of the Container Apps."
  value       = { for n, app in azurerm_container_app.app : n => app.id }
}

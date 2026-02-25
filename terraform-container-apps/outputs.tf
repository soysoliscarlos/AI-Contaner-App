# -----------------------------------------------------------------------------
# Outputs del despliegue de Container Apps.
# -----------------------------------------------------------------------------

output "container_app_fqdn" {
  description = "FQDN de cada Container App desplegada."
  value       = module.container_app.container_app_fqdn
}

output "container_app_ids" {
  description = "IDs de los recursos Container App desplegados."
  value       = module.container_app.container_app_ids
}

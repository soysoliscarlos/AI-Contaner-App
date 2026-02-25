output "workload_identity_id" {
  description = "Resource ID of the User Assigned Managed Identity (for Container App identity block)."
  value       = azurerm_user_assigned_identity.workload.id
}

output "workload_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity (set as AZURE_CLIENT_ID in the app)."
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "workload_identity_principal_id" {
  description = "Principal (object) ID of the User Assigned Managed Identity."
  value       = azurerm_user_assigned_identity.workload.principal_id
}

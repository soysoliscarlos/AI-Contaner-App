variable "resource_group_name" {
  description = "Name of the resource group."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "name_prefix" {
  description = "Prefix for resource names."
  type        = string
}

variable "container_apps_subnet_id" {
  description = "ID of the subnet delegated to Microsoft.App/environments (from network module)."
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace (from ai_services module)."
  type        = string
}

variable "workload_identity_id" {
  description = "Resource ID of the User Assigned Managed Identity (for future Container App)."
  type        = string
}

variable "workload_identity_client_id" {
  description = "Client ID of the User Assigned Managed Identity (for future Container App env AZURE_CLIENT_ID)."
  type        = string
}

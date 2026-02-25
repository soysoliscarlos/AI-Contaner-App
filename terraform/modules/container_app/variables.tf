variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "container_app_environment_name" {
  description = "Name of the Container App Environment."
  type        = string
}

variable "container_registry_name" {
  description = "Name of the Azure Container Registry."
  type        = string
}

variable "workload_managed_identity_name" {
  description = "Name of the User Assigned Managed Identity."
  type        = string
}

variable "container_apps" {
  description = "List of Container App definitions."
  type        = any
}

variable "container_app_secrets" {
  description = "Secrets per app: map of app name to list of { name, value }."
  type        = map(list(object({
    name  = string
    value = string
  })))
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Tags for Container Apps."
  type        = map(string)
  default     = {}
}

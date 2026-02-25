variable "name" {
  description = "Name of the Container Registry (must be globally unique, 5-50 alphanumeric)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "sku" {
  description = "SKU: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"
}

variable "admin_enabled" {
  description = "Enable admin user (not needed when using AcrPull with Managed Identity)."
  type        = bool
  default     = false
}

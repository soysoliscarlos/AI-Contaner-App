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

variable "virtual_network_cidr" {
  description = "CIDR for the virtual network."
  type        = string
  default     = "10.0.0.0/16"
}

variable "container_apps_subnet_cidr" {
  description = "CIDR for Container Apps subnet (delegated to Microsoft.App/environments)."
  type        = string
  default     = "10.0.0.0/23"
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR for private endpoints subnet."
  type        = string
  default     = "10.0.2.0/24"
}

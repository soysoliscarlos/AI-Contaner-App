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

variable "openai_id" {
  description = "Resource ID of the Azure OpenAI Cognitive Services account (for RBAC scope)."
  type        = string
}

variable "search_service_id" {
  description = "Resource ID of the Azure AI Search service (for RBAC scope)."
  type        = string
}

variable "acr_id" {
  description = "Resource ID of the Azure Container Registry (for AcrPull role)."
  type        = string
}

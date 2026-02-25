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

variable "openai_sku" {
  description = "SKU for Azure OpenAI (e.g. S0)."
  type        = string
  default     = "S0"
}

variable "openai_deployments" {
  description = "List of OpenAI model deployments (name, model.name, model.version)."
  type = list(object({
    name = string
    model = object({
      name    = string
      version = string
    })
  }))
}

variable "openai_public_network_access_enabled" {
  description = "Allow public network access to Azure OpenAI."
  type        = bool
  default     = true
}

variable "search_sku" {
  description = "SKU for Azure AI Search (basic or standard)."
  type        = string
}

variable "search_replica_count" {
  description = "Number of replicas for Azure AI Search."
  type        = number
  default     = 1
}

variable "search_partition_count" {
  description = "Number of partitions for Azure AI Search."
  type        = number
  default     = 1
}

variable "search_local_authentication_enabled" {
  description = "Allow API key auth on Search. false = RBAC only."
  type        = bool
  default     = false
}

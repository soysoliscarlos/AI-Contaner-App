# -----------------------------------------------------------------------------
# Root variables for Zero-Trust AI infrastructure (Azure OpenAI, AI Search, Container Apps)
# All variables have validations; no API keys or secrets.
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix for all Azure resource names (alphanumeric, 3-18 chars)."
  type        = string
  default     = "ai0trust"

  validation {
    condition     = length(var.name_prefix) >= 3 && length(var.name_prefix) <= 18 && can(regex("^[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "name_prefix must be 3-18 characters and alphanumeric only."
  }
}

variable "location" {
  description = "Azure region for all resources (e.g. EastUS, WestEurope)."
  type        = string
  default     = "EastUS"

  validation {
    condition     = length(var.location) > 0
    error_message = "location must not be empty."
  }
}

# -----------------------------------------------------------------------------
# Azure OpenAI
# -----------------------------------------------------------------------------

variable "openai_sku" {
  description = "SKU for Azure OpenAI Cognitive Services account (e.g. S0)."
  type        = string
  default     = "S0"
}

variable "openai_deployments" {
  description = "List of model deployments for Azure OpenAI. Each needs name and model (name + version). Adjust version per region availability."
  type = list(object({
    name = string
    model = object({
      name    = string
      version = string
    })
  }))
  default = [
    {
      name = "gpt-4o"
      model = {
        name    = "gpt-4o"
        version = "2024-08-06"
      }
    },
    {
      name = "text-embedding-3-small"
      model = {
        name    = "text-embedding-3-small"
        version = "1"
      }
    }
  ]
}

variable "openai_public_network_access_enabled" {
  description = "Allow public network access to Azure OpenAI. Set to false when using private endpoints only."
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Azure AI Search
# -----------------------------------------------------------------------------

variable "search_sku" {
  description = "SKU for Azure AI Search (basic or standard)."
  type        = string
  default     = "standard"

  validation {
    condition     = contains(["basic", "standard"], var.search_sku)
    error_message = "search_sku must be 'basic' or 'standard'."
  }
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
  description = "Allow API key authentication on Azure AI Search. Set to false for RBAC-only (Zero-Trust)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Network (subnet CIDRs)
# -----------------------------------------------------------------------------

variable "container_apps_subnet_cidr" {
  description = "CIDR for the subnet used by Container Apps Environment (must be delegated to Microsoft.App/environments)."
  type        = string
  default     = "10.0.0.0/23"
}

variable "private_endpoints_subnet_cidr" {
  description = "CIDR for the subnet used by private endpoints (OpenAI, Search, etc.)."
  type        = string
  default     = "10.0.2.0/24"
}

variable "virtual_network_cidr" {
  description = "CIDR for the virtual network (must encompass both subnets)."
  type        = string
  default     = "10.0.0.0/16"
}

# -----------------------------------------------------------------------------
# Private endpoints (align with Azure sample container-apps-openai)
# -----------------------------------------------------------------------------

variable "use_private_endpoints" {
  description = "Create private endpoints and Private DNS zones for OpenAI and ACR (Zero-Trust)."
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# Azure Container Registry (for container images, as in Azure sample)
# -----------------------------------------------------------------------------

variable "acr_sku" {
  description = "SKU for Azure Container Registry: Basic, Standard, or Premium."
  type        = string
  default     = "Basic"
}

variable "acr_admin_enabled" {
  description = "Enable ACR admin user. Set to false when using AcrPull with Managed Identity."
  type        = bool
  default     = false
}

# Container Apps se despliegan en terraform-container-apps/ (despliegue Terraform separado).

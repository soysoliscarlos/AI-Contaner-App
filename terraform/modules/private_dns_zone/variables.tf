variable "name" {
  description = "Private DNS zone name (e.g. privatelink.openai.azure.com)."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "vnet_id" {
  description = "Virtual network ID to link for private DNS resolution."
  type        = string
}

variable "vnet_name" {
  description = "Virtual network name (used for link name)."
  type        = string
}

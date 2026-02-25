variable "name" {
  description = "Name of the private endpoint."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the private endpoint."
  type        = string
}

variable "private_connection_resource_id" {
  description = "Resource ID of the target resource (e.g. OpenAI account, ACR)."
  type        = string
}

variable "subresource_names" {
  description = "List of subresource names (e.g. ['account'] for OpenAI, ['registry'] for ACR)."
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "List of Private DNS zone IDs for the private_dns_zone_group."
  type        = list(string)
  default     = []
}

variable "private_dns_zone_group_name" {
  description = "Name of the private DNS zone group."
  type        = string
  default     = "default"
}

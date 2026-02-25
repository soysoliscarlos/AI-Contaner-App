# -----------------------------------------------------------------------------
# Variables para el despliegue de Container Apps.
# name_prefix debe coincidir con el usado en terraform/ (infra).
# -----------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix de la infra desplegada (debe coincidir con terraform/). Ej: ai0trust."
  type        = string

  validation {
    condition     = length(var.name_prefix) >= 3 && length(var.name_prefix) <= 18 && can(regex("^[a-zA-Z0-9]+$", var.name_prefix))
    error_message = "name_prefix must be 3-18 characters and alphanumeric only."
  }
}

variable "container_apps" {
  description = "Lista de Container Apps a desplegar (nombre, template con containers, ingress, etc.)."
  type        = list(any)
}

variable "container_app_secrets" {
  description = "Secrets por Container App. Clave = nombre de la app, valor = lista de { name, value }."
  type        = map(list(object({
    name  = string
    value = string
  })))
  default     = {}
  sensitive   = true
}

variable "tags" {
  description = "Tags para las Container Apps."
  type        = map(string)
  default     = {}
}

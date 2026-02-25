# -----------------------------------------------------------------------------
# Despliegue de Container Apps (independiente de la infra).
# Requiere: infra ya desplegada con terraform/ (mismo name_prefix).
# Usa data sources para enlazar: RG, Container App Environment, ACR, Workload Identity.
# -----------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Enlace con la infra desplegada por terraform/ (mismo name_prefix).
data "azurerm_resource_group" "rg" {
  name = "${var.name_prefix}-rg"
}

# Container App(s): despliegue en el entorno creado por la infra.
module "container_app" {
  source = "./modules/container_app"

  resource_group_name             = data.azurerm_resource_group.rg.name
  container_app_environment_name  = "${var.name_prefix}-ca-env"
  container_registry_name         = "${var.name_prefix}acr"
  workload_managed_identity_name   = "${var.name_prefix}-workload-identity"
  container_apps                  = var.container_apps
  container_app_secrets           = var.container_app_secrets
  tags                            = try(var.tags, {})
}

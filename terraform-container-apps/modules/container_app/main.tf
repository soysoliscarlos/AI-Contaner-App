# -----------------------------------------------------------------------------
# Deploys one or more Azure Container App(s). Uses existing Environment, ACR,
# and Workload Identity (data sources). Injects AZURE_CLIENT_ID for DefaultAzureCredential.
# -----------------------------------------------------------------------------

data "azurerm_container_app_environment" "env" {
  name                = var.container_app_environment_name
  resource_group_name = var.resource_group_name
}

data "azurerm_container_registry" "acr" {
  name                = var.container_registry_name
  resource_group_name = var.resource_group_name
}

data "azurerm_user_assigned_identity" "workload" {
  name                = var.workload_managed_identity_name
  resource_group_name = var.resource_group_name
}

locals {
  identity = {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.workload.id]
  }
  identity_env = {
    name        = "AZURE_CLIENT_ID"
    secret_name = null
    value       = data.azurerm_user_assigned_identity.workload.client_id
  }
  registry = {
    server   = data.azurerm_container_registry.acr.login_server
    identity = data.azurerm_user_assigned_identity.workload.id
  }
  container_app_secrets = {
    for k, v in var.container_app_secrets : k => { for p in v : p.name => p.value }
  }
}

resource "azurerm_container_app" "app" {
  for_each = { for app in var.container_apps : app.name => app }

  name                       = each.key
  container_app_environment_id = data.azurerm_container_app_environment.env.id
  resource_group_name        = var.resource_group_name
  revision_mode              = try(each.value.revision_mode, "Single")
  tags                       = try(each.value.tags, {})

  template {
    min_replicas    = try(each.value.template.min_replicas, 0)
    max_replicas    = try(each.value.template.max_replicas, 10)
    revision_suffix = try(each.value.template.revision_suffix, null)

    dynamic "container" {
      for_each = each.value.template.containers
      content {
        name   = container.value.name
        image  = "${data.azurerm_container_registry.acr.login_server}/${container.value.image}"
        cpu    = try(container.value.cpu, "0.5")
        memory = try(container.value.memory, "1Gi")
        args   = try(container.value.args, null)
        command = try(container.value.command, null)

        dynamic "env" {
          for_each = concat(try(container.value.env, []), [local.identity_env])
          content {
            name        = env.value.name
            secret_name = env.value.secret_name
            value       = env.value.value
          }
        }

        dynamic "liveness_probe" {
          for_each = try(container.value.liveness_probe, null) != null ? [container.value.liveness_probe] : []
          content {
            port                    = liveness_probe.value.port
            transport               = try(liveness_probe.value.transport, "HTTP")
            failure_count_threshold = try(liveness_probe.value.failure_count_threshold, 3)
            initial_delay           = try(liveness_probe.value.initial_delay, 1)
            interval_seconds        = try(liveness_probe.value.interval_seconds, 10)
            path                    = try(liveness_probe.value.path, "/")
            timeout                 = try(liveness_probe.value.timeout, 1)
          }
        }

        dynamic "readiness_probe" {
          for_each = try(container.value.readiness_probe, null) != null ? [container.value.readiness_probe] : []
          content {
            port                    = readiness_probe.value.port
            transport               = try(readiness_probe.value.transport, "HTTP")
            failure_count_threshold = try(readiness_probe.value.failure_count_threshold, 3)
            interval_seconds        = try(readiness_probe.value.interval_seconds, 10)
            path                    = try(readiness_probe.value.path, "/")
            success_count_threshold = try(readiness_probe.value.success_count_threshold, 1)
            timeout                 = try(readiness_probe.value.timeout, 1)
          }
        }
      }
    }

    dynamic "volume" {
      for_each = try(each.value.template.volume, [])
      content {
        name         = volume.value.name
        storage_name = try(volume.value.storage_name, null)
        storage_type = try(volume.value.storage_type, "EmptyDir")
      }
    }
  }

  dynamic "ingress" {
    for_each = try(each.value.ingress, null) != null ? [each.value.ingress] : []
    content {
      target_port                  = ingress.value.target_port
      external_enabled             = try(ingress.value.external_enabled, true)
      allow_insecure_connections   = try(ingress.value.allow_insecure_connections, false)
      transport                    = try(ingress.value.transport, "http")
      dynamic "traffic_weight" {
        for_each = [try(ingress.value.traffic_weight, { percentage = 100, latest_revision = true })]
        content {
          percentage      = traffic_weight.value.percentage
          latest_revision = try(traffic_weight.value.latest_revision, true)
          revision_suffix = try(traffic_weight.value.revision_suffix, null)
          label           = try(traffic_weight.value.label, null)
        }
      }
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [data.azurerm_user_assigned_identity.workload.id]
  }

  registry {
    server               = data.azurerm_container_registry.acr.login_server
    identity             = data.azurerm_user_assigned_identity.workload.id
    password_secret_name = null
    username             = null
  }

  dynamic "secret" {
    for_each = nonsensitive(toset([for p in lookup(var.container_app_secrets, each.key, []) : p.name]))
    content {
      name  = secret.key
      value = local.container_app_secrets[each.key][secret.key]
    }
  }
}

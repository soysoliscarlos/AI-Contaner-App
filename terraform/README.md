# Zero-Trust AI Infrastructure (Terraform)

**El despliegue con Terraform es en dos partes:** (1) **infra** — solo infraestructura; (2) **container_apps** — Container Apps (chat, doc), tras tener la infra y las imágenes en el ACR.

Infraestructura modular en Azure para IA: **Azure OpenAI** (gpt-4o, text-embedding-3-small), **Azure AI Search**, **Azure Container Registry (ACR)**, **Container Apps Environment**, con **Managed Identity** y **RBAC** (sin API keys). Opcionalmente: **Private DNS zones** y **Private Endpoints** para OpenAI y ACR (Zero-Trust). Alineado con el [sample de Azure container-apps-openai](https://github.com/Azure-Samples/container-apps-openai/tree/main/terraform/infra).

## Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (para autenticación)
- Suscripción de Azure con permisos para crear Resource Groups, OpenAI, AI Search, Container Apps, redes y asignaciones de roles

## Autenticación

```bash
az login
az account set --subscription "<subscription-id>"
```

Terraform usará el contexto de la CLI (no se requieren variables de entorno de credenciales si usas `az login`).

## Registro de proveedores de Azure

Antes del primer `terraform apply`, la suscripción debe tener registrado el proveedor **Microsoft.App** (Azure Container Apps). Si aparece el error `MissingSubscriptionRegistration: The subscription is not registered to use namespace 'Microsoft.App'`, ejecuta:

```bash
az provider register --namespace Microsoft.App
```

Comprueba el estado (puede tardar unos minutos):

```bash
az provider show --namespace Microsoft.App --query "registrationState" -o tsv
```

Cuando devuelva `Registered`, vuelve a ejecutar `terraform apply`.

## Uso rápido

1. **Inicializar**
   ```bash
   cd terraform
   terraform init
   ```

2. **Configurar variables** (opcional)  
   Copia `terraform.tfvars.example` a `terraform.tfvars` y ajusta `name_prefix` y `location` si lo deseas. Por defecto se usa `location = "EastUS"` y `name_prefix = "ai0trust"`.

3. **Parte 1: Solo infra**  
   Con `container_apps = []` en `terraform.tfvars` (por defecto), este apply crea **solo la infraestructura** (OpenAI, ACR, Container App Environment, Managed Identity, etc.).
   ```bash
   terraform plan -var-file=terraform.tfvars -out=tfplan
   terraform apply tfplan
   ```
   Desde la raíz del repo también puedes usar: `.\deploy-terraform-infra.ps1`

4. **Parte 2: Container Apps** (después del build/push desde `src/`)  
   Copia `terraform.container-apps.tfvars.example` a `terraform.container-apps.tfvars` y aplica con ambos archivos de variables:
   ```bash
   cp terraform.container-apps.tfvars.example terraform.container-apps.tfvars
   terraform plan -var-file=terraform.tfvars -var-file=terraform.container-apps.tfvars -out=tfplan-apps
   terraform apply tfplan-apps
   ```
   Desde la raíz del repo también puedes usar: `.\deploy-terraform-container-apps.ps1`

## Estructura

- **modules/network** — VNet y subnets (Container Apps + Private Endpoints).
- **modules/ai_services** — Log Analytics, Azure OpenAI, Azure AI Search.
- **modules/container_registry** — Azure Container Registry (imágenes para Container Apps).
- **modules/private_dns_zone** / **modules/private_endpoint** — Private DNS y endpoints (cuando `use_private_endpoints = true`).
- **modules/workload_identity** — User Assigned Managed Identity + roles (Cognitive Services OpenAI User, Search Index Data Contributor, AcrPull).
- **modules/container_apps** — Container Apps Environment (entorno).
- **modules/container_app** — Módulo que despliega una o más Container App(s); se invoca desde el root cuando `container_apps` no está vacío.

## Salidas importantes

Después del `apply`, usa estas salidas para configurar tu aplicación:

| Output | Uso |
|--------|-----|
| `openai_endpoint` | URL del recurso OpenAI (ej. `https://<name>.openai.azure.com/`). |
| `openai_deployment_names` | Nombres de despliegue (gpt-4o, text-embedding-3-small). |
| `search_endpoint` | URL de Azure AI Search. |
| `search_name` | Nombre del servicio Search (para SDK). |
| `workload_identity_client_id` | Valor para la variable de entorno `AZURE_CLIENT_ID` en el contenedor. |
| `workload_identity_id` | Resource ID de la identidad (para el bloque `identity` del Container App). |
| `container_app_environment_id` | ID del entorno donde desplegar la app. |
| `acr_login_server` | Servidor ACR (ej. `<name>.azurecr.io`) para la imagen del Container App. |
| `container_app_fqdn` | FQDN de cada Container App desplegada (si definiste `container_apps`). |
| `container_app_ids` | IDs de los recursos Container App (si definiste `container_apps`). |

En la aplicación usa **DefaultAzureCredential** (o **ManagedIdentityCredential** con `AZURE_CLIENT_ID`); no configures API keys.

## Backend remoto (opcional)

Para guardar el estado en Azure Storage, crea un storage account y un contenedor, luego en `main.tf` descomenta el bloque `backend "azurerm"` y rellena:

- `resource_group_name`
- `storage_account_name`
- `container_name`
- `key`

Vuelve a ejecutar `terraform init` para migrar el estado.

## Comparación con el sample de Azure

Este código despliega los mismos tipos de recursos que [container-apps-openai/terraform/infra](https://github.com/Azure-Samples/container-apps-openai/tree/main/terraform/infra):

| Recurso | Sample Azure | Este proyecto |
|---------|----------------|---------------|
| Resource Group | ✓ | ✓ |
| Log Analytics | ✓ | ✓ |
| Virtual Network + subnets | ✓ | ✓ |
| Private DNS (OpenAI) | ✓ | ✓ (si `use_private_endpoints = true`) |
| Private DNS (ACR) | ✓ | ✓ (si `use_private_endpoints = true`) |
| Private Endpoint (OpenAI) | ✓ | ✓ (si `use_private_endpoints = true`) |
| Private Endpoint (ACR) | ✓ | ✓ (si `use_private_endpoints = true`) |
| Azure OpenAI | ✓ | ✓ |
| Azure Container Registry | ✓ | ✓ |
| Managed Identity (OpenAI + AcrPull) | ✓ | ✓ (+ Search Index Data Contributor) |
| Container Apps Environment | ✓ | ✓ |
| Azure AI Search | — | ✓ (extra para RAG/embeddings) |

Variables relevantes: `use_private_endpoints` (default `false`; ponla a `true` para alinear con el sample con Private Link), `acr_sku`, `acr_admin_enabled`.

### Container App(s) en un despliegue aparte

El [sample container-apps-openai/terraform/apps](https://github.com/Azure-Samples/container-apps-openai/tree/main/terraform/apps) usa una carpeta `apps/` aparte. En este proyecto: **(1)** el primer apply despliega solo la infra (`container_apps = []` en `terraform.tfvars`); **(2)** desde `src/` se construyen y suben las imágenes al ACR; **(3)** un segundo apply con `-var-file=terraform.container-apps.tfvars` despliega las Container App(s). Todo desde la raíz de `terraform/`, sin carpeta `apps/` separada.

| Recurso / concepto | En este proyecto |
|--------------------|------------------|
| azurerm_container_app (una o más) | ✓ cuando `container_apps` no está vacío |
| Inyección AZURE_CLIENT_ID, registry con identidad (AcrPull) | ✓ |
| Ingress, env, secrets, probes | ✓ (módulo `modules/container_app`) |

Las salidas **`container_app_fqdn`** y **`container_app_ids`** aparecen cuando hay al menos una app desplegada.

## Private Endpoints

Por defecto `use_private_endpoints = false` (acceso público). Para Zero-Trust como en el sample, en `terraform.tfvars` define `use_private_endpoints = true`; se crearán Private DNS zones y private endpoints para OpenAI y ACR. Opcionalmente pon `openai_public_network_access_enabled = false` para que OpenAI solo sea accesible por Private Link.

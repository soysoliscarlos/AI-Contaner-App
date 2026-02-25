# Zero-Trust AI Infrastructure (Terraform)

**Este directorio (`terraform/`) despliega solo la infraestructura.** Las Container Apps (chat, doc) se despliegan por separado desde el directorio **terraform-container-apps/** usando `.\deploy-terraform-container-apps.ps1` en la raíz del repo (tras tener la infra y las imágenes en el ACR).

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

3. **Solo infra (este directorio)**  
   Con `container_apps = []` en `terraform.tfvars` (por defecto), este apply crea **solo la infraestructura** (OpenAI, ACR, Container App Environment, Managed Identity, etc.).
   ```bash
   terraform plan -var-file=terraform.tfvars -out=tfplan
   terraform apply tfplan
   ```
   Desde la raíz del repo: `.\deploy-terraform-infra.ps1`. Si algún comando terraform falla, el script termina con ese código de salida (y `deploy-all.ps1` se detiene).

4. **Container Apps (directorio aparte)**  
   Las Container Apps se despliegan desde **terraform-container-apps/** (no desde este directorio). Tras el build/push desde `src/`, desde la raíz ejecuta: `.\deploy-terraform-container-apps.ps1`. Ver README raíz y `terraform-container-apps/`.

## Estructura

- **modules/network** — VNet y subnets (Container Apps + Private Endpoints).
- **modules/ai_services** — Log Analytics, Azure OpenAI, Azure AI Search.
- **modules/container_registry** — Azure Container Registry (imágenes para Container Apps).
- **modules/private_dns_zone** / **modules/private_endpoint** — Private DNS y endpoints (cuando `use_private_endpoints = true`).
- **modules/workload_identity** — User Assigned Managed Identity + roles (Cognitive Services OpenAI User, Search Index Data Contributor, AcrPull).
- **modules/container_apps** — Container Apps Environment (entorno). Las aplicaciones (chat, doc) se despliegan en **terraform-container-apps/** con su propio Terraform.

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
| `container_app_fqdn` | FQDN de cada Container App (se obtiene tras aplicar en `terraform-container-apps/`). |
| `container_app_ids` | IDs de los recursos Container App (en `terraform-container-apps/`). |

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

### Container Apps en directorio aparte

El [sample container-apps-openai/terraform/apps](https://github.com/Azure-Samples/container-apps-openai/tree/main/terraform/apps) usa una carpeta `apps/` aparte. En este proyecto: **(1)** este directorio `terraform/` despliega solo la infra (`container_apps = []`); **(2)** desde `src/` se construyen y suben las imágenes al ACR; **(3)** el directorio **terraform-container-apps/** despliega las Container Apps con su propio `terraform apply` (script `.\deploy-terraform-container-apps.ps1` desde la raíz). Las salidas **`container_app_fqdn`** y **`container_app_ids`** se obtienen tras aplicar en `terraform-container-apps/`.

## Private Endpoints

Por defecto `use_private_endpoints = false` (acceso público). Para Zero-Trust como en el sample, en `terraform.tfvars` define `use_private_endpoints = true`; se crearán Private DNS zones y private endpoints para OpenAI y ACR. Opcionalmente pon `openai_public_network_access_enabled = false` para que OpenAI solo sea accesible por Private Link.

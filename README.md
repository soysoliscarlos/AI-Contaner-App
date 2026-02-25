# Microsoft Azure Panama User Group — Zero-Trust AI

Repositorio unificado: **infraestructura en Terraform** (Azure OpenAI, AI Search, ACR, Container Apps) y **aplicaciones de chat** (Chainlit + OpenAI + RAG) para desplegar en Azure sin API keys, usando Managed Identity.

---

## Índice

1. [Visión general](#visión-general)
2. [Chat (Chainlit)](#chat-chainlit)
3. [Infraestructura (Terraform)](#infraestructura-terraform)
4. [Aplicaciones (src/)](#aplicaciones-src)
5. [Despliegue completo](#despliegue-completo)
6. [Outputs de Terraform](#outputs-de-terraform)
7. [Referencias](#referencias)

---

## Visión general

| Carpeta | Contenido |
|---------|-----------|
| **terraform/** | Infraestructura Azure: OpenAI, AI Search, ACR, Container Apps **Environment**, Managed Identity. Opcional: Private Endpoints. *No incluye las Container Apps (chat, doc).* |
| **terraform-container-apps/** | Despliegue Terraform **independiente**: solo las Container Apps (chat, doc). Usa la infra ya desplegada en `terraform/`. |
| **src/** | Apps de chat (Chat simple y Documents QA con RAG), Dockerfile y scripts para build/push a ACR. |

El despliegue con **Terraform es en dos directorios**: (1) **terraform/** — apply solo infraestructura; (2) **terraform-container-apps/** — apply solo Container Apps (requiere mismo `name_prefix` e imágenes en ACR). Entre ambos va el build y push del código desde `src/` al ACR.

---

## Chat (Chainlit)

Texto de bienvenida de la UI (ver `src/chainlit.md`):

**Funny Chat** — Bienvenida a la app de chat: curiosidad, humor e imaginación.

### Enlaces útiles

- **Documentación:** [Chainlit Documentation](https://docs.chainlit.io)
- **Comunidad:** [Chainlit Discord](https://discord.gg/ZThrUxbAYw)

---

## Infraestructura (Terraform)

Infraestructura modular en Azure para IA: **Azure OpenAI** (gpt-4o, text-embedding-3-small), **Azure AI Search**, **Azure Container Registry (ACR)**, **Container Apps Environment**, con **Managed Identity** y **RBAC** (sin API keys). Opcionalmente: **Private DNS zones** y **Private Endpoints** para OpenAI y ACR (Zero-Trust). Alineado con el [sample de Azure container-apps-openai](https://github.com/Azure-Samples/container-apps-openai/tree/main/terraform/infra).

### Requisitos

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.5.0
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) (para autenticación)
- Suscripción de Azure con permisos para crear Resource Groups, OpenAI, AI Search, Container Apps, redes y asignaciones de roles

### Autenticación

```bash
az login
az account set --subscription "<subscription-id>"
```

Terraform usará el contexto de la CLI (no se requieren variables de entorno de credenciales si usas `az login`).

### Registro de proveedores de Azure

Antes del primer `terraform apply`, la suscripción debe tener registrado el proveedor **Microsoft.App** (Azure Container Apps). Si aparece el error `MissingSubscriptionRegistration`:

```bash
az provider register --namespace Microsoft.App
az provider show --namespace Microsoft.App --query "registrationState" -o tsv
```

Cuando devuelva `Registered`, vuelve a ejecutar `terraform apply`.

### Uso rápido (terraform)

1. **Inicializar**
   ```bash
   cd terraform
   terraform init
   ```

2. **Configurar variables (opcional)**  
   Copia `terraform.tfvars.example` a `terraform.tfvars` y ajusta `name_prefix` y `location`. Por defecto: `location = "EastUS"`, `name_prefix = "ai0trust"`. Si tu `terraform.tfvars` tiene `container_apps` o `container_app_secrets`, elimínalos (las apps se despliegan en `terraform-container-apps/`).

3. **Plan y apply (solo infra)**  
   Con `container_apps = []` en `terraform.tfvars` (por defecto), este apply crea solo la infra (OpenAI, ACR, Container App Environment, Managed Identity). Las Container Apps se despliegan en un **paso aparte** (ver [Despliegue completo](#despliegue-completo)).
   ```bash
   terraform plan -out=tfplan
   terraform apply tfplan
   ```

### Estructura (terraform) — solo infra

- **modules/network** — VNet y subnets (Container Apps + Private Endpoints).
- **modules/ai_services** — Log Analytics, Azure OpenAI, Azure AI Search.
- **modules/container_registry** — Azure Container Registry.
- **modules/private_dns_zone** / **modules/private_endpoint** — Private DNS y endpoints (cuando `use_private_endpoints = true`).
- **modules/workload_identity** — User Assigned Managed Identity + roles (Cognitive Services OpenAI User, Search Index Data Contributor, AcrPull).
- **modules/container_apps** — Container Apps **Environment** (entorno donde luego se despliegan las apps).

Las **Container Apps** (chat, doc) se despliegan en el directorio separado **terraform-container-apps/** (ver más abajo).

### Backend remoto (opcional)

Para guardar el estado en Azure Storage, crea un storage account y un contenedor, descomenta el bloque `backend "azurerm"` en `terraform/main.tf` y rellena `resource_group_name`, `storage_account_name`, `container_name`, `key`. Luego ejecuta `terraform init` de nuevo.

### Comparación con el sample de Azure

| Recurso | Sample Azure | Este proyecto |
|---------|----------------|----------------|
| Resource Group, Log Analytics, VNet, subnets | ✓ | ✓ |
| Private DNS / Private Endpoints (OpenAI, ACR) | ✓ | ✓ (si `use_private_endpoints = true`) |
| Azure OpenAI, ACR, Managed Identity, Container Apps Environment | ✓ | ✓ |
| Azure AI Search | — | ✓ (extra para RAG/embeddings) |
| Container App(s) | carpeta `apps/` aparte | directorio **terraform-container-apps/** separado |

Variables relevantes: `use_private_endpoints` (default `false`), `acr_sku`, `acr_admin_enabled`.

### Private Endpoints

Por defecto `use_private_endpoints = false`. Para Zero-Trust, en `terraform.tfvars` define `use_private_endpoints = true`; se crearán Private DNS zones y private endpoints para OpenAI y ACR. Opcionalmente `openai_public_network_access_enabled = false` para que OpenAI solo sea accesible por Private Link.

---

## Aplicaciones (src/)

Código de las aplicaciones de chat del proyecto [Azure-Samples/container-apps-openai](https://github.com/Azure-Samples/container-apps-openai), alojado aquí (hermano de `terraform/`).

### Qué hace este código

- **Simple Chat (`chat.py`)**: interfaz tipo ChatGPT con [Chainlit](https://docs.chainlit.io), que llama al modelo de chat de **Azure OpenAI** (completions en streaming). Usa **DefaultAzureCredential** (Managed Identity en Container Apps; en local opcionalmente API key).
- **Documents QA Chat (`doc.py`)**: misma UI con Chainlit; el usuario sube archivos **PDF/DOCX**. La app extrae texto con LangChain, genera embeddings con Azure OpenAI, guarda vectores en **ChromaDB** (en memoria) y responde con **RAG** (RetrievalQAWithSourcesChain).

Ambas apps se desplegarán como **Azure Container Apps** tras desplegar la infra con Terraform.

### Estructura (src/)

| Archivo / carpeta | Uso |
|-------------------|-----|
| `chat.py`, `doc.py` | Apps de chat y QA sobre documentos. |
| `requirements.txt` | Dependencias (Chainlit, OpenAI, Azure Identity, LangChain, ChromaDB, pypdf, python-docx). |
| `Dockerfile` | Imagen multi-stage: `chainlit run <FILENAME> --port=<PORT>`. |
| `chainlit.md` | Texto de bienvenida en la UI. |
| `.chainlit/config.toml` | Configuración de Chainlit. |
| `00-variables.sh` / `00-variables.ps1` | Variables (prefix, ACR, nombres, puerto). |
| `01-build-docker-images.sh` / `.ps1` | Construye imágenes Docker Chat y Doc. |
| `02-run-docker-container.sh` / `.ps1` | Ejecuta en local el contenedor Chat o Doc. |
| `03-push-docker-image.sh` / `.ps1` | Login ACR y push de imágenes. |
| `.env.example` | Ejemplo de variables de entorno (OpenAI, auth, Managed Identity). |

Scripts `.sh` para WSL/bash; `.ps1` para PowerShell en Windows. Mantén los mismos valores en `00-variables.sh` y `00-variables.ps1` si usas ambos.

### Requisitos (src/)

- Python 3.11+
- Docker (para construir y subir imágenes)
- Azure CLI (para `az acr login` y auth local con `az login`)
- PowerShell 5.1+ (Windows) para `.ps1`, o WSL/bash para `.sh`

### Uso rápido en local (src/)

1. Copiar y rellenar variables de entorno:
   ```powershell
   cd src
   Copy-Item .env.example .env
   ```
   Rellenar `.env` con Azure OpenAI (endpoint, deployments). En local: `AZURE_OPENAI_TYPE=azure` y `AZURE_OPENAI_KEY`; en Container Apps: `AZURE_OPENAI_TYPE=azure_ad` y `AZURE_CLIENT_ID` (workload identity).

2. Instalar y ejecutar:
   ```bash
   pip install -r requirements.txt
   chainlit run chat.py --port=8000
   # o
   chainlit run doc.py --port=8000
   ```
3. Abrir la URL que indique Chainlit (p. ej. http://localhost:8000).

### Build y push de imágenes

1. Ajustar `00-variables.ps1` o `00-variables.sh`: `prefix` y `acrName` deben coincidir con Terraform (p. ej. `ai0trust`, `ai0trustacr`).
2. Construir:
   ```powershell
   cd src
   .\01-build-docker-images.ps1
   ```
   ```bash
   bash ./01-build-docker-images.sh
   ```
3. Push a ACR:
   ```powershell
   .\03-push-docker-image.ps1
   ```
   ```bash
   bash ./03-push-docker-image.sh
   ```

### Ejecutar contenedor en local (Chat o Doc)

```powershell
.\02-run-docker-container.ps1 1   # Chat
.\02-run-docker-container.ps1 2   # Doc
```

```bash
bash ./02-run-docker-container.sh   # menú interactivo
```

---

## Despliegue completo (tres pasos)

El despliegue se hace en **tres pasos separados**: primero la infra, luego el código de las apps en el ACR, y por último las Container Apps.

**Terraform en dos directorios (PowerShell):** `.\deploy-terraform-infra.ps1` (infra en `terraform/`) y `.\deploy-terraform-container-apps.ps1` (Container Apps en `terraform-container-apps/`; requiere infra desplegada e imágenes en ACR; `name_prefix` debe coincidir).

**Los tres pasos de una vez:** `.\deploy-all.ps1` ejecuta: Terraform infra → build/push desde `src/` → Terraform Container Apps. Requiere `az login` y Terraform en el PATH.

**Eliminar todo:** `.\destroy-all.ps1` ejecuta primero `terraform destroy` en `terraform-container-apps/` y luego en `terraform/` (no pide confirmación).

### Paso 1 — Despliegue de la infra

En `terraform/`, con `container_apps = []` en `terraform.tfvars` (valor por defecto):

```bash
cd terraform
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

Se crean: Resource Group, OpenAI, AI Search, ACR, Container App Environment, Managed Identity, red, etc. **No** se crean aún las Container Apps (chat, doc).

### Paso 2 — App: build y push del código (src/)

En `src/`, construir las imágenes y subirlas al ACR creado en el paso 1. Ajusta `00-variables.ps1` o `00-variables.sh` para que `prefix` y `acrName` coincidan con Terraform (p. ej. `ai0trust`, `ai0trustacr`).

```powershell
cd src
.\01-build-docker-images.ps1
.\03-push-docker-image.ps1
```

```bash
cd src
bash ./01-build-docker-images.sh
bash ./03-push-docker-image.sh
```

Requiere `az login`. Las imágenes `chat:v1` y `doc:v1` quedan en el ACR.

### Paso 3 — Despliegue de las Container Apps

En **terraform-container-apps/** (despliegue Terraform independiente). El `name_prefix` en `terraform.tfvars` debe coincidir con el de `terraform/terraform.tfvars`.

```bash
cd terraform-container-apps
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

Se crean las Container Apps que usan las imágenes `chat:v1` y `doc:v1` del ACR. Las apps usan Managed Identity; no hace falta configurar API keys.

### URLs de las apps

Tras el paso 3: `cd terraform-container-apps && terraform output container_app_fqdn` para las URLs públicas de Chat y Doc (p. ej. `https://chat.xxx.azurecontainerapps.io` y `https://doc.xxx.azurecontainerapps.io`).

---

## Outputs de Terraform

**Infra (terraform/):** tras `terraform apply` en `terraform/`:

| Output | Uso |
|--------|-----|
| `name_prefix` | Coincidir con `terraform-container-apps/terraform.tfvars`. |
| `acr_login_server` | Registro ACR para subir `chat:v1` y `doc:v1`. |
| `openai_endpoint`, `openai_deployment_names` | Azure OpenAI. |
| `search_endpoint`, `search_name` | Azure AI Search. |
| `workload_identity_client_id`, `workload_identity_id` | Identidad usada por las Container Apps. |
| `container_app_environment_id` | ID del entorno Container Apps. |

**Container Apps (terraform-container-apps/):** tras `terraform apply` en `terraform-container-apps/`:

| Output | Uso |
|--------|-----|
| `container_app_fqdn` | URLs de las Container Apps (chat, doc). |
| `container_app_ids` | IDs de los recursos Container App. |

En la aplicación usa **DefaultAzureCredential** (o **ManagedIdentityCredential** con `AZURE_CLIENT_ID`); no configures API keys.

---

## Referencias

- [Chainlit Documentation](https://docs.chainlit.io) · [Chainlit Discord](https://discord.gg/ZThrUxbAYw)
- [container-apps-openai (Azure Samples)](https://github.com/Azure-Samples/container-apps-openai) · [README del sample](https://github.com/Azure-Samples/container-apps-openai/blob/main/README.md)
- [Terraform](https://developer.hashicorp.com/terraform/downloads) · [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)

Documentación detallada por carpeta: **terraform/README.md** y **src/README.md**.

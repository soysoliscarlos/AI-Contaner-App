# Chat apps (OpenAI + Chainlit + LangChain + ChromaDB)

Código de las aplicaciones de chat del proyecto [Azure-Samples/container-apps-openai](https://github.com/Azure-Samples/container-apps-openai), alojado aquí a nivel de repositorio (hermano de `terraform/`).

## Qué hace este código

- **Simple Chat (`chat.py`)**: interfaz tipo ChatGPT con [Chainlit](https://docs.chainlit.io), que llama al modelo de chat de **Azure OpenAI** (completions en streaming). Usa **DefaultAzureCredential** (Managed Identity en Container Apps; en local opcionalmente API key).
- **Documents QA Chat (`doc.py`)**: misma UI con Chainlit; el usuario sube hasta N archivos **PDF/DOCX**. La app:
  1. Extrae texto y lo trocea con **LangChain** (RecursiveCharacterTextSplitter).
  2. Genera embeddings con **Azure OpenAI** (modelo de embeddings).
  3. Guarda los vectores en **ChromaDB** (en memoria en esta versión).
  4. Responde preguntas con **RAG** (RetrievalQAWithSourcesChain) usando el modelo de chat de Azure OpenAI y las fuentes encontradas.

Ambas apps están pensadas para desplegarse como **Azure Container Apps** tras desplegar la infra con el Terraform de este repo (`terraform/`).

## Estructura

| Archivo / carpeta | Uso |
|-------------------|-----|
| `chat.py` | App de chat simple (OpenAI chat completion + Chainlit). |
| `doc.py` | App de QA sobre documentos (embeddings + ChromaDB + RAG + Chainlit). |
| `requirements.txt` | Dependencias Python (Chainlit, OpenAI, Azure Identity, LangChain, ChromaDB, pypdf, python-docx). |
| `Dockerfile` | Imagen multi-stage: instala deps y ejecuta `chainlit run <FILENAME> --port=<PORT>`. |
| `chainlit.md` | Texto de bienvenida en la UI de Chainlit. |
| `.chainlit/config.toml` | Configuración de Chainlit (nombre, visibilidad, etc.). |
| `00-variables.sh` / `00-variables.ps1` | Variables para los scripts (prefix, ACR, nombres, puerto). Editar el que uses. |
| `01-build-docker-images.sh` / `.ps1` | Construye imágenes Docker para Chat y Doc. |
| `02-run-docker-container.sh` / `.ps1` | Ejecuta en local el contenedor Chat o Doc. |
| `03-push-docker-image.sh` / `.ps1` | Login ACR, tag y push de las imágenes al registro. |
| `.env.example` | Ejemplo de variables de entorno (OpenAI, tipo de auth, Managed Identity). |

Los scripts `.sh` están pensados para **WSL** o bash en Linux/macOS; los `.ps1` para **PowerShell** en Windows. Mantén los mismos valores en `00-variables.sh` y `00-variables.ps1` si usas ambos entornos.

## Requisitos

- Python 3.11+
- Docker (para construir y subir imágenes)
- Azure CLI (para `az acr login` y, en local, auth con `az login`)
- **PowerShell** 5.1+ (Windows) para los `.ps1`, o **WSL/bash** para los `.sh`

## Uso rápido en local

1. Copiar variables de entorno:
   ```powershell
   # PowerShell
   cd src
   Copy-Item .env.example .env
   ```
   ```bash
   # WSL / bash
   cd src
   cp .env.example .env
   ```
2. Rellenar `.env` con tu recurso Azure OpenAI (endpoint, deployments). Para auth con identidad en local puedes usar `AZURE_OPENAI_TYPE=azure` y `AZURE_OPENAI_KEY`; en Container Apps se usa `AZURE_OPENAI_TYPE=azure_ad` y `AZURE_CLIENT_ID` (workload identity).
3. Instalar dependencias y ejecutar:
   ```bash
   pip install -r requirements.txt
   chainlit run chat.py --port=8000
   # o
   chainlit run doc.py --port=8000
   ```
4. Abrir la URL que indique Chainlit (p. ej. http://localhost:8000).

## Build y push de imágenes (para Container Apps)

Los scripts `01-build-docker-images.ps1` y `03-push-docker-image.ps1` comprueban el código de salida de cada comando (docker, az) y terminan con error si fallan, de modo que `deploy-all.ps1` se detenga y no continúe con los pasos siguientes.

1. Ajustar variables: en **PowerShell** edita `00-variables.ps1`, en **WSL/bash** edita `00-variables.sh`. `prefix` y `acrName` deben coincidir con tu Terraform (p. ej. `ai0trust` y `ai0trustacr`).
2. Construir imágenes:
   ```powershell
   # PowerShell (desde src/)
   .\01-build-docker-images.ps1
   ```
   ```bash
   # WSL / bash (desde src/)
   bash ./01-build-docker-images.sh
   ```
3. Login en ACR y push:
   ```powershell
   .\03-push-docker-image.ps1
   ```
   ```bash
   bash ./03-push-docker-image.sh
   ```
4. Desplegar las Container Apps con `terraform/` (variable `container_apps` en `terraform.tfvars`) usando las imágenes `chat:v1` y `doc:v1` (o el tag que uses) en el ACR creado por `terraform/`.

## Despliegue completo (paso 2 de tres)

El despliegue se hace en **tres pasos**. Este `src/` es el **paso 2** (app: build y push del código). Debe ir **después** del paso 1 (infra con Terraform) y **antes** del paso 3 (despliegue de las Container Apps con Terraform).

1. **Paso 1 ya hecho**  
   En `terraform/` debe estar desplegada la infra (`terraform apply` con `container_apps = []`). Outputs útiles: `acr_login_server`, `openai_endpoint`, `workload_identity_client_id`, etc.

2. **Paso 2: Construir imágenes** (desde `src/`):
   ```powershell
   .\01-build-docker-images.ps1
   ```
   ```bash
   bash ./01-build-docker-images.sh
   ```

3. **Paso 2: Subir imágenes al ACR** (requiere `az login` y `prefix`/`acrName` en `00-variables` alineados con Terraform):
   ```powershell
   .\03-push-docker-image.ps1
   ```
   ```bash
   bash ./03-push-docker-image.sh
   ```

4. **Paso 3 (terraform-container-apps/)**  
   Desplegar las Container Apps desde el directorio **terraform-container-apps/** (desde la raíz: `.\deploy-terraform-container-apps.ps1`). Tras eso, `cd terraform-container-apps && terraform output container_app_fqdn` muestra las URLs de Chat y Doc. Las apps usan Managed Identity; no hace falta configurar API keys.

### Ejecutar contenedor en local (Chat o Doc)

```powershell
# PowerShell: 1 = Chat, 2 = Doc (o sin argumento para elegir por prompt)
.\02-run-docker-container.ps1 1
.\02-run-docker-container.ps1 2
```
```bash
# WSL / bash: menú interactivo
bash ./02-run-docker-container.sh
```

## Relación con el resto del repo

- **terraform/** (paso 1) crea la infra (OpenAI, ACR, Container App Environment, Managed Identity, etc.).
- **terraform-container-apps/** (paso 3) despliega las Container Apps que usan las imágenes construidas desde este **src/**.
- **src/** (paso 2) proporciona el código de las dos apps (Chat y Documents QA) y los scripts para construir y subir las imágenes al ACR. El script `02-run-docker-container.ps1` es solo para pruebas en local y no forma parte de `deploy-all.ps1`.

## Outputs de Terraform (referencia)

Tras `terraform apply`, puedes usar estos outputs para configurar `.env` en local o verificar el despliegue:

| Output | Ejemplo / uso |
|--------|----------------|
| `acr_login_server` | `ai0trustacr.azurecr.io` — registro donde se suben `chat:v1` y `doc:v1`. |
| `openai_endpoint` | `https://ai0trustopenai.openai.azure.com/` — endpoint para Azure OpenAI. |
| `openai_deployment_names` | `gpt-4o`, `text-embedding-3-small` — nombres de despliegue. |
| `search_endpoint` | `https://ai0trust-search.search.windows.net` — Azure AI Search. |
| `search_name` | `ai0trust-search` — nombre del servicio Search. |
| `workload_identity_client_id` | Client ID de la Managed Identity; en Container Apps se inyecta como `AZURE_CLIENT_ID`. |
| `container_app_fqdn` | URLs de las Container Apps (chat, doc) una vez desplegadas. |
| `container_app_ids` | IDs de los recursos Container App. |

Para ver los valores: `cd terraform && terraform output`.

Documentación original del sample: [README del proyecto container-apps-openai](https://github.com/Azure-Samples/container-apps-openai/blob/main/README.md).

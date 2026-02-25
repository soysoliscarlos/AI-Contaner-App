<#
.SYNOPSIS
  Despliegue completo: infra (terraform/), build/push (src/), Container Apps (terraform-container-apps/).
.DESCRIPTION
  Tres pasos en orden:
  1. terraform/     — Infraestructura (OpenAI, AI Search, ACR, Container App Environment, Managed Identity).
  2. src/           — Build y push de imágenes Docker al ACR (solo 01-build y 03-push).
  3. terraform-container-apps/ — Despliegue de las Container Apps (chat, doc).

  El script 02-run-docker-container.ps1 no se ejecuta aquí: es para probar contenedores en local
  (docker run -it) y no forma parte del flujo de despliegue a Azure. Uso manual: cd src; .\02-run-docker-container.ps1 1|2

  Ejecutar desde la raíz del repo. Requiere: az login, Terraform en PATH.
.EXAMPLE
  .\deploy-all.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot

# ---------- 1. Infra (terraform/) ----------
& (Join-Path $RepoRoot "deploy-terraform-infra.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

# ---------- 2. Build y push (src/) ----------
# Solo 01 y 03. 02-run-docker-container.ps1 es para test local (interactivo); no se invoca en deploy.
Write-Host "`n========== Build y push de imágenes (src/) ==========" -ForegroundColor Cyan
$SrcDir = Join-Path $RepoRoot "src"
Push-Location $SrcDir
try {
    & (Join-Path $SrcDir "01-build-docker-images.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & (Join-Path $SrcDir "03-push-docker-image.ps1")
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
} finally {
    Pop-Location
}

# ---------- 3. Container Apps (terraform-container-apps/) ----------
& (Join-Path $RepoRoot "deploy-terraform-container-apps.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "`n========== Despliegue completado ==========" -ForegroundColor Green

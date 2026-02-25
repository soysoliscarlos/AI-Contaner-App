<#
.SYNOPSIS
  Elimina toda la infraestructura: primero Container Apps, luego infra.
.DESCRIPTION
  1. terraform destroy en terraform-container-apps/ (Container Apps), si existe state.
  2. terraform destroy en terraform/ (infra: RG, OpenAI, AI Search, ACR, Container App Environment, Managed Identity, red).
  Ejecutar desde la raíz del repo. No pide confirmación (-auto-approve).
.EXAMPLE
  .\destroy-all.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$ContainerAppsDir = Join-Path $RepoRoot "terraform-container-apps"
$TerraformDir = Join-Path $RepoRoot "terraform"
$ContainerAppsTfvars = Join-Path $ContainerAppsDir "terraform.tfvars"

# 1. Container Apps (terraform-container-apps/)
Write-Host "`n========== 1/2: Container Apps (terraform-container-apps/) ==========" -ForegroundColor Yellow
if (Test-Path (Join-Path $ContainerAppsDir "terraform.tfstate")) {
    Push-Location $ContainerAppsDir
    try {
        terraform init -input=false
        $varFiles = if (Test-Path $ContainerAppsTfvars) { @("-var-file=terraform.tfvars") } else { @() }
        terraform destroy @varFiles -input=false -auto-approve -no-color
    } finally {
        Pop-Location
    }
} else {
    Write-Host "No hay state en terraform-container-apps/; omitiendo." -ForegroundColor Gray
}

# 2. Infra (terraform/)
Write-Host "`n========== 2/2: Infraestructura (terraform/) ==========" -ForegroundColor Yellow
Push-Location $TerraformDir
try {
    terraform init -input=false
    terraform destroy -var-file="terraform.tfvars" -input=false -auto-approve -no-color
} finally {
    Pop-Location
}

Write-Host "`n========== Infraestructura eliminada ==========" -ForegroundColor Green

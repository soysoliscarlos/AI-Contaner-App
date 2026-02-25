<#
.SYNOPSIS
  Despliegue Terraform de infraestructura (terraform/). Sin Container Apps.
.DESCRIPTION
  Ejecuta en terraform/: init, plan y apply con terraform.tfvars.
  Crea: Resource Group, OpenAI, AI Search, ACR, Container App Environment, Managed Identity, red.
  Las Container Apps se despliegan por separado en terraform-container-apps/ (deploy-terraform-container-apps.ps1).
.EXAMPLE
  .\deploy-terraform-infra.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$TerraformDir = Join-Path $RepoRoot "terraform"

Write-Host "`n========== Terraform: Infraestructura (terraform/) ==========" -ForegroundColor Cyan
Push-Location $TerraformDir
try {
    terraform init -input=false
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
    terraform plan -var-file="terraform.tfvars" -out="tfplan" -input=false -no-color
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
    terraform apply -input=false -no-color tfplan
    if ($LASTEXITCODE -ne 0) { Pop-Location; exit $LASTEXITCODE }
} finally {
    Pop-Location
}
Write-Host "`n========== Infra desplegada. Siguiente: build/push en src/ y luego .\deploy-terraform-container-apps.ps1 ==========" -ForegroundColor Green

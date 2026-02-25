<#
.SYNOPSIS
  Despliegue Terraform de Container Apps (terraform-container-apps/).
.DESCRIPTION
  Requiere: (1) infra en terraform/ ya desplegada (deploy-terraform-infra.ps1), (2) imágenes en ACR (build/push desde src/).
  Ejecuta en terraform-container-apps/: init, plan y apply con terraform.tfvars.
  name_prefix en terraform-container-apps/terraform.tfvars debe coincidir con terraform/terraform.tfvars.
.EXAMPLE
  .\deploy-terraform-container-apps.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$ContainerAppsDir = Join-Path $RepoRoot "terraform-container-apps"
$TfvarsExample = Join-Path $ContainerAppsDir "terraform.tfvars.example"
$Tfvars = Join-Path $ContainerAppsDir "terraform.tfvars"

Write-Host "`n========== Terraform: Container Apps (terraform-container-apps/) ==========" -ForegroundColor Cyan

if (-not (Test-Path $Tfvars)) {
    Write-Host "Creando terraform.tfvars desde terraform.tfvars.example." -ForegroundColor Gray
    Copy-Item $TfvarsExample $Tfvars
}

Push-Location $ContainerAppsDir
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
Write-Host "`n========== Container Apps desplegadas. URLs: cd terraform-container-apps; terraform output container_app_fqdn ==========" -ForegroundColor Green

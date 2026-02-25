<#
.SYNOPSIS
  Elimina toda la infraestructura: primero APPS, después TERRAD (ver ambientes.md).
.DESCRIPTION
  Dos ambientes, en este orden (ver ambientes.md):

  1. APPS (Container Apps)
     Directorio: terraform-container-apps/
     Comando: terraform destroy -var-file="terraform.tfvars" -auto-approve

  2. TERRAD (Infraestructura base)
     Directorio: terraform/
     Comando: terraform destroy -var-file="terraform.tfvars" -auto-approve

  Orden: Primero APPS, después TERRAD (la infra base depende de que no queden
  Container Apps en el entorno).

  Tras un destroy exitoso en cada ambiente, purga tfplan*, terraform.tfstate y
  terraform.tfstate.backup en ese directorio. Ejecutar desde la raíz del repo.
  No pide confirmación (-auto-approve).
.EXAMPLE
  .\destroy-all.ps1
#>

$ErrorActionPreference = "Stop"
$RepoRoot = $PSScriptRoot
$ContainerAppsDir = Join-Path $RepoRoot "terraform-container-apps"
$TerraformDir = Join-Path $RepoRoot "terraform"
$ContainerAppsTfvars = Join-Path $ContainerAppsDir "terraform.tfvars"

function Remove-TerraformGeneratedFiles {
    param(
        [string]$Dir
    )
    $files = @(
        (Join-Path $Dir "terraform.tfstate"),
        (Join-Path $Dir "terraform.tfstate.backup")
    )
    foreach ($f in $files) {
        if (Test-Path $f) { Remove-Item $f -Force; Write-Host "  Eliminado: $f" -ForegroundColor Gray }
    }
    Get-ChildItem -Path $Dir -Filter "tfplan*" -File -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "  Eliminado: $($_.FullName)" -ForegroundColor Gray
    }
}

# 1. APPS (Container Apps) — terraform-container-apps/ (ver ambientes.md)
Write-Host "`n========== 1/2: APPS (Container Apps) — terraform-container-apps/ ==========" -ForegroundColor Yellow
if (Test-Path (Join-Path $ContainerAppsDir "terraform.tfstate")) {
    Push-Location $ContainerAppsDir
    try {
        terraform init -input=false
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (Test-Path $ContainerAppsTfvars) {
            cmd /c "terraform destroy -var-file=terraform.tfvars -auto-approve -input=false -no-color"
        } else {
            cmd /c "terraform destroy -auto-approve -input=false -no-color"
        }
        $destroyExit = $LASTEXITCODE
        if ($destroyExit -eq 0) {
            Write-Host "Purga de archivos en terraform-container-apps/..." -ForegroundColor Cyan
            Remove-TerraformGeneratedFiles -Dir $ContainerAppsDir
        } else {
            Write-Host "terraform destroy en APPS falló (exit $destroyExit). No se ejecuta destroy de TERRAD." -ForegroundColor Red
            exit $destroyExit
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "No hay state en APPS (terraform-container-apps/); omitiendo." -ForegroundColor Gray
}

# 2. TERRAD (Infraestructura base) — terraform/ (ver ambientes.md)
Write-Host "`n========== 2/2: TERRAD (Infraestructura base) — terraform/ ==========" -ForegroundColor Yellow
if (Test-Path (Join-Path $TerraformDir "terraform.tfstate")) {
    Push-Location $TerraformDir
    try {
        terraform init -input=false
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        if (Test-Path (Join-Path $TerraformDir "terraform.tfvars")) {
            cmd /c "terraform destroy -var-file=terraform.tfvars -auto-approve -input=false -no-color"
        } else {
            cmd /c "terraform destroy -auto-approve -input=false -no-color"
        }
        $destroyExit2 = $LASTEXITCODE
        if ($destroyExit2 -eq 0) {
            Write-Host "Purga de archivos en terraform/..." -ForegroundColor Cyan
            Remove-TerraformGeneratedFiles -Dir $TerraformDir
        }
    } finally {
        Pop-Location
    }
} else {
    Write-Host "No hay state en TERRAD (terraform/); omitiendo." -ForegroundColor Gray
}

Write-Host "`n========== Destrucción completada (APPS + TERRAD). Ver ambientes.md ==========" -ForegroundColor Green

# Run Chat or Doc container locally. Set AZURE_OPENAI_* in env or .env (see .env.example).
# See: https://github.com/Azure-Samples/container-apps-openai
# PowerShell: .\02-run-docker-container.ps1 [1|2]
# WSL: bash ./02-run-docker-container.sh

. "$PSScriptRoot\00-variables.ps1"

# Load .env into process environment if present
$envPath = Join-Path $PSScriptRoot ".env"
if (Test-Path $envPath) {
    Get-Content $envPath | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
            [Environment]::SetEnvironmentVariable($matches[1].Trim(), $matches[2].Trim(), 'Process')
        }
    }
}

$choice = $args[0]
if (-not $choice) {
    Write-Host "======================================"
    Write-Host "Run Docker container (1=Chat, 2=Doc):"
    Write-Host "======================================"
    $choice = Read-Host "Enter 1 (Chat), 2 (Doc), or q (Quit)"
}

switch ($choice) {
    "1" {
        docker run -it --rm -p "${port}:${port}" `
            -e AZURE_OPENAI_BASE `
            -e AZURE_OPENAI_KEY `
            -e AZURE_OPENAI_DEPLOYMENT `
            -e AZURE_OPENAI_MODEL `
            -e AZURE_OPENAI_VERSION `
            -e AZURE_OPENAI_TYPE `
            -e AZURE_CLIENT_ID `
            -e TEMPERATURE `
            --name $chatImageName `
            "${chatImageName}:$tag"
    }
    "2" {
        docker run -it --rm -p "${port}:${port}" `
            -e AZURE_OPENAI_BASE `
            -e AZURE_OPENAI_KEY `
            -e AZURE_OPENAI_DEPLOYMENT `
            -e AZURE_OPENAI_ADA_DEPLOYMENT `
            -e AZURE_OPENAI_MODEL `
            -e AZURE_OPENAI_VERSION `
            -e AZURE_OPENAI_TYPE `
            -e AZURE_CLIENT_ID `
            -e TEMPERATURE `
            --name $docImageName `
            "${docImageName}:$tag"
    }
    "q" { exit 0 }
    default {
        Write-Host "Invalid option. Use 1 (Chat), 2 (Doc), or q (Quit)."
        exit 1
    }
}

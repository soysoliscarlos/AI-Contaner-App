# Login to ACR, tag and push Chat and Doc images. Run from src/ after 01-build-docker-images.
# See: https://github.com/Azure-Samples/container-apps-openai
# PowerShell: .\03-push-docker-image.ps1
# WSL: bash ./03-push-docker-image.sh

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\00-variables.ps1"

Write-Host "Logging in to [$acrName] container registry..."
az acr login --name $acrName
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Retrieving login server for [$acrName]..."
$loginServer = (az acr show --name $acrName --query loginServer --output tsv)
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

for ($i = 0; $i -lt $images.Count; $i++) {
    $img = "$($images[$i]):$tag"
    $target = "$loginServer/$($images[$i]):$tag"
    Write-Host "Tagging and pushing $img -> $target"
    docker tag $img $target
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    docker push $target
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Write-Host "Done. Use terraform/ (container_apps in terraform.tfvars) to deploy Container Apps with these images."

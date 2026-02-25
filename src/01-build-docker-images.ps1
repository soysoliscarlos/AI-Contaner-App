# Build Docker images for Chat and Doc apps. Run from src/.
# See: https://github.com/Azure-Samples/container-apps-openai
# PowerShell: .\01-build-docker-images.ps1
# WSL: bash ./01-build-docker-images.sh

$ErrorActionPreference = "Stop"
. "$PSScriptRoot\00-variables.ps1"

for ($i = 0; $i -lt $images.Count; $i++) {
    $img = $images[$i]
    $fn = $filenames[$i]
    Write-Host "Building ${img}:$tag (FILENAME=$fn)..."
    docker build -t "${img}:$tag" -f Dockerfile `
        --build-arg FILENAME="$fn" `
        --build-arg PORT="$port" .
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Write-Host "Done. Push with 03-push-docker-image.ps1 (or .sh) after logging into ACR."

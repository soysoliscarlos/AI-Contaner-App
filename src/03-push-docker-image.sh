#!/usr/bin/env bash
# Login to ACR, tag and push Chat and Doc images. Run from src/ after 01-build-docker-images.
# See: https://github.com/Azure-Samples/container-apps-openai
# WSL/Linux: bash ./03-push-docker-image.sh  or  ./03-push-docker-image.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-variables.sh"

echo "Logging in to [$acrName] container registry..."
az acr login --name "$acrName"

echo "Retrieving login server for [$acrName]..."
loginServer=$(az acr show --name "$acrName" --query loginServer --output tsv)

for index in ${!images[@]}; do
  img="${images[$index]}:$tag"
  target="$loginServer/${images[$index]}:$tag"
  echo "Tagging and pushing $img -> $target"
  docker tag "$img" "$target"
  docker push "$target"
done
echo "Done. Use terraform/ (container_apps in terraform.tfvars) to deploy Container Apps with these images."

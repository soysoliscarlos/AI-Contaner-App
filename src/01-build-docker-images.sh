#!/usr/bin/env bash
# Build Docker images for Chat and Doc apps. Run from src/.
# See: https://github.com/Azure-Samples/container-apps-openai
# WSL/Linux: bash ./01-build-docker-images.sh  or  ./01-build-docker-images.sh

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-variables.sh"

for index in ${!images[@]}; do
  echo "Building ${images[$index]}:$tag (FILENAME=${filenames[$index]})..."
  docker build -t "${images[$index]}:$tag" -f Dockerfile \
    --build-arg FILENAME="${filenames[$index]}" \
    --build-arg PORT="$port" .
done
echo "Done. Push with 03-push-docker-image.sh (or .ps1) after logging into ACR."

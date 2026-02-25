#!/usr/bin/env bash
# Run Chat or Doc container locally. Set AZURE_OPENAI_* in env or .env (see .env.example).
# See: https://github.com/Azure-Samples/container-apps-openai
# WSL/Linux: bash ./02-run-docker-container.sh  or  ./02-run-docker-container.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/00-variables.sh"

echo "======================================"
echo "Run Docker container (1=Chat, 2=Doc):"
echo "======================================"
options=("Chat" "Doc" "Quit")
select option in "${options[@]}"; do
  case $option in
    "Chat")
      docker run -it --rm -p $port:$port \
        -e AZURE_OPENAI_BASE \
        -e AZURE_OPENAI_KEY \
        -e AZURE_OPENAI_DEPLOYMENT \
        -e AZURE_OPENAI_MODEL \
        -e AZURE_OPENAI_VERSION \
        -e AZURE_OPENAI_TYPE \
        -e AZURE_CLIENT_ID \
        -e TEMPERATURE \
        --name $chatImageName \
        $chatImageName:$tag
      break
      ;;
    "Doc")
      docker run -it --rm -p $port:$port \
        -e AZURE_OPENAI_BASE \
        -e AZURE_OPENAI_KEY \
        -e AZURE_OPENAI_DEPLOYMENT \
        -e AZURE_OPENAI_ADA_DEPLOYMENT \
        -e AZURE_OPENAI_MODEL \
        -e AZURE_OPENAI_VERSION \
        -e AZURE_OPENAI_TYPE \
        -e AZURE_CLIENT_ID \
        -e TEMPERATURE \
        --name $docImageName \
        $docImageName:$tag
      break
      ;;
    "Quit") exit ;;
    *) echo "Invalid option $REPLY" ;;
  esac
done

# Variables for build/run/push scripts. Align with terraform name_prefix (e.g. ai0trust).
# See: https://github.com/Azure-Samples/container-apps-openai/tree/main/src

# Azure Container Registry (must match terraform output acr_login_server prefix)
prefix="ai0trust"
acrName="${prefix}acr"
acrResourceGroupName="${prefix}-rg"
location="eastus"

# Python app files
docAppFile="doc.py"
chatAppFile="chat.py"

# Docker images and tag
docImageName="doc"
chatImageName="chat"
tag="v1"
port="8000"

# Arrays for scripts
images=($docImageName $chatImageName)
filenames=($docAppFile $chatAppFile)

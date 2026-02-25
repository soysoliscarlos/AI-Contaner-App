# Variables for build/run/push scripts. Align with terraform name_prefix (e.g. ai0trust).
# See: https://github.com/Azure-Samples/container-apps-openai/tree/main/src
# Usage: . .\00-variables.ps1

$script:prefix = "ai0trust"
$script:acrName = "${prefix}acr"
$script:acrResourceGroupName = "${prefix}-rg"
$script:location = "eastus"

$script:docAppFile = "doc.py"
$script:chatAppFile = "chat.py"

$script:docImageName = "doc"
$script:chatImageName = "chat"
$script:tag = "v1"
$script:port = "8000"

$script:images = @($docImageName, $chatImageName)
$script:filenames = @($docAppFile, $chatAppFile)

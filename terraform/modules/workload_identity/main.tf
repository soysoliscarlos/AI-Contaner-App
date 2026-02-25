# -----------------------------------------------------------------------------
# Workload Identity module: User Assigned Managed Identity + RBAC.
# No API keys: app uses DefaultAzureCredential and AZURE_CLIENT_ID.
# Roles: Cognitive Services OpenAI User, Search Index Data Contributor.
# -----------------------------------------------------------------------------

resource "azurerm_user_assigned_identity" "workload" {
  name                = "${var.name_prefix}-workload-identity"
  resource_group_name = var.resource_group_name
  location            = var.location
}

# Grant the identity permission to use Azure OpenAI (chat + embeddings).
resource "azurerm_role_assignment" "openai" {
  scope                = var.openai_id
  role_definition_name  = "Cognitive Services OpenAI User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
  skip_service_principal_aad_check = true
}

# Grant the identity permission to read/write Azure AI Search index data.
resource "azurerm_role_assignment" "search" {
  scope                = var.search_service_id
  role_definition_name  = "Search Index Data Contributor"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
  skip_service_principal_aad_check = true
}

# Grant the identity permission to pull images from ACR (for Container Apps).
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name  = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
  skip_service_principal_aad_check = true
}

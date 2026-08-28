


// role for service principal to access GitLab API
resource "azurerm_role_assignment" "gitlab_api_access" {
  principal_id   = azuread_service_principal.gitlab_sp.id
  role_definition_name = "Contributor"
  scope          = var.gitlab_base_url
}

// role for service principal to access storage account for Terraform state
resource "azurerm_role_assignment" "gitlab_storage_access" {
  principal_id   = azuread_service_principal.gitlab_sp.id
  role_definition_name = "Storage Blob Data Contributor"
  scope          = "/subscriptions/${var.subscription_id}/resourceGroups/cicdprojectdev-rg/providers/Microsoft.Storage/storageAccounts/cicdprojectstatedev"
}


resource "gitlab_project_variable" "gitlab_token_variable" {
  project = data.gitlab_project.gitlab_project.id
  key     = "GITLAB_TOKEN"
  value   = var.gitlab_token
  protected = true
  masked    = true
}

// create project variable for the Azure AD tenant ID
resource "gitlab_project_variable" "azuread_tenant_id_variable" {
  project = data.gitlab_project.gitlab_project.id
  key     = "AZUREAD_TENANT_ID"
  value   = var.tenant_id
  protected = true
  masked    = true
}

// create project variable for the Azure subscription ID
resource "gitlab_project_variable" "azure_subscription_id_variable" {
  project = data.gitlab_project.gitlab_project.id
  key     = "AZURE_SUBSCRIPTION_ID"
  value   = var.subscription_id
  protected = true
  masked    = true
}

// create project variable for client ID
# resource "gitlab_project_variable" "azure_client_id_variable" {
#   project = data.gitlab_project.gitlab_project.id
#   key     = "AZURE_CLIENT_ID"
#   value   = var.azure_client_id
#   protected = true
#   masked    = true
# }  


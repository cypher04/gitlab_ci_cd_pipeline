data "azurerm_client_config" "current" {

}

// app registration the pipeline will use to access the GitLab API
resource "azuread_application" "gitlab_app" {
  display_name = "gitlab-app"
  owners       = [data.azurerm_client_config.current.object_id]
  sign_in_audience = "AzureADMyOrg"
}


// service principal for the app registration
resource "azuread_service_principal" "gitlab_sp" {
  client_id = azuread_application.gitlab_app.id
  owners         = [data.azurerm_client_config.current.object_id]
}


// fedred identity for the service principal
resource "azuread_application_federated_identity_credential" "gitlab_federal_identity" {
  display_name                       = "gitlab-federated-identity"
  application_id = azuread_application.gitlab_app.id
  description                        = "Federated identity for GitLab CI/CD pipeline"
  audiences                          = [var.gitlab_base_url]
  issuer                             = var.gitlab_base_url
  subject                            = "project_path:/${var.gitlab_namespace}/${var.gitlab_project_name}:ref_type:branch:ref:${var.default_branch}"
}
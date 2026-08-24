terraform {
    required_providers {
        azurerm = {
        source  = "hashicorp/azurerm"
        version = "~> 4.80.0"
        }

        azuread = {
        source  = "hashicorp/azuread"
        version = "~> 3.9.0"
        }

        gitlab = {
        source  = "gitlabhq/gitlab"
        version = "~> 19.2.1"
        }
    }
}

data "azurerm_client_config" "current" {

}

provider "azurerm" {
    features {}
}

provider "azuread" {
    tenant_id = data.azurerm_client_config.current.tenant_id
}

provider "gitlab" {
    base_url = var.gitlab_base_url
}
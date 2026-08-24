// backend configuration for Terraform state
terraform {
  backend "azurerm" {
    resource_group_name  = "cicdprojectdev-rg"
    storage_account_name = "cicdprojectstatedev"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.80.0"
    }


  }
}

data "azurerm_client_config" "current" {

}

provider "azurerm" {
  features {}
}
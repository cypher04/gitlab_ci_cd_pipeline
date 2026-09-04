// import the existing resource group into the state file

# import {
#   id = "/subscriptions/fe797b99-c79d-4fe3-baa0-091bacc96c3a/resourceGroups/cicd-resource-group"
#   to = module.networking.cicd-resource-group
# }

module "compute" {
  source = "../../modules/compute"
  location = var.location
  vm_password = var.vm_password
  subnet_ids = module.networking.subnet_ids[0]
}

module "networking" {
  source             = "../../modules/networking"
  location           = var.location
  vnet_address_space = var.vnet_address_space
  subnet_prefixes    = var.subnet_prefixes
}
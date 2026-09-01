module "compute" {
  source              = "../../modules/compute"

}

module "networking" {
  source             = "../../modules/networking"
  location           = var.location
  vnet_address_space = var.vnet_address_space
  subnet_prefixes    = var.subnet_prefixes
}
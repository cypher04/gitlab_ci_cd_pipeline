module "compute" {
    source              = "../../modules/compute"
    resource_group_name = var.resource_group_name
    location            = var.location
}

module "networking" {
    source              = "../../modules/networking"
    location            = var.location
    vnet_address_space  = var.vnet_address_space
    subnet_prefixes     = var.subnet_prefixes
}
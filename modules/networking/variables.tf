variable "vnet_address_space" {
    description = "The address space for the virtual network."
    type        = list(string)
}

variable "location" {
    description = "The Azure region where the virtual network will be created."
    type        = string
}


variable "subnet_prefixes" {
    description = "The address prefixes for the subnet."
    type        = map(string)
}
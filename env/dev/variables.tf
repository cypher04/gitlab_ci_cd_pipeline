
variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
}

variable "subnet_prefixes" {
  description = "A map of subnet names to their respective CIDR prefixes."
  type        = map(string)
}

variable "vnet_address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
}

variable "resource_group_name" {
  description = "The name of the resource group to create."
  type        = string
}

variable "vm_password" {
  description = "The password for the virtual machines."
  type        = string
}
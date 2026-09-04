variable "location" {
  description = "The location where resources will be created"
  type        = string
}

variable "vm_password" {
  description = "The admin password for the Linux virtual machine"
  type        = string
  sensitive   = true
}

variable "subnet_ids" {
  description = "The ID of the subnet where the network interface will be created"
  type        = list(string)
}
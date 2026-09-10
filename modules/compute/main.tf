
data "azurerm_client_config" "current" {}


// resource group configuration
resource "azurerm_resource_group" "compute-rg" {
  name     = "compute-rg"
  location = var.location
}
  
// network interface configuration
resource "azurerm_network_interface" "example" {
  name                = "infra-vm-nic"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[1]
    private_ip_address_allocation = "Dynamic"
  }
}

// linux virtual machine configuration

resource "azurerm_linux_virtual_machine" "infra_vm" {
    name                  = "infra-vm"
    resource_group_name   = azurerm_resource_group.compute-rg.name
    location              = var.location
    size                  = "Standard_D2als_v6"
    admin_username        = "adminuser"
    admin_password        = null
    network_interface_ids = [azurerm_network_interface.example.id]
    disable_password_authentication = true

    os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    admin_ssh_key {
      username   = "adminuser"
      public_key = var.admin_ssh_public_key
    }

    source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts-gen2"
      version   = "latest"

    }
}

// deploy bastion host

resource "azurerm_bastion_host" "vm_bastion" {
  name                = "vm-bastion"
  location            = var.location
  resource_group_name = azurerm_resource_group.compute-rg.name


  ip_configuration {
    name                 = "internal"
    subnet_id            = var.subnet_ids[3]
    public_ip_address_id = var.bastion_public_ip_id
  }
}
// resource group configuration
resource "azurerm_resource_group" "compute-rg" {
  name     = "compute-rg"
  location = var.location
}
  
// network interface configuration
resource "azurerm_network_interface" "example" {
  name                = "infra-vm-nic"
  location            = azurerm_resource_group.compute-rg.location
  resource_group_name = azurerm_resource_group.compute-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[1]
    private_ip_address_allocation = "Dynamic"
  }
}

// linux virtual machine configuration

resource "azurerm_linux_virtual_machine" "infra_vm" {
    name                = "infra-vm"
    resource_group_name   = azurerm_resource_group.compute-rg.name
    location              = azurerm_resource_group.compute-rg.location
    size                  = "Standard_DS1_v2"
    admin_username        = "adminuser"
    admin_password        = var.vm_password
    network_interface_ids = [azurerm_network_interface.example.id]

    os_disk {
      caching              = "ReadWrite"
      storage_account_type = "Standard_LRS"
    }

    source_image_reference {
      publisher = "Canonical"
      offer     = "0001-com-ubuntu-server-jammy"
      sku       = "22_04-lts"
      version   = "latest"

    }
}
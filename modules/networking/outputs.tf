output "resource_group_id" {
    value = azurerm_resource_group.rg.id
}

output "subnet_ids" {
    value = [
        azurerm_subnet.subnet.id,
        azurerm_subnet.db.id,
        azurerm_subnet.app.id,
        azurerm_subnet.AzureBastionSubnet.id
    ]
}

output "bastion_public_ip_id" {
    value = azurerm_public_ip.bastion_pip.id
}

output "bastion_public_ip" {
    value = azurerm_public_ip.bastion_pip.ip_address
}
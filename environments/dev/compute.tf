resource "azurerm_public_ip" "jump" {
  name                = "pip-${local.name_prefix}-jump"
  location            = azurerm_resource_group.main["compute"].location
  resource_group_name = azurerm_resource_group.main["compute"].name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.common_tags
}

resource "azurerm_network_interface" "main" {
  for_each            = var.subnets
  name                = "nic-${local.name_prefix}-${each.key}"
  location            = azurerm_resource_group.main["compute"].location
  resource_group_name = azurerm_resource_group.main["compute"].name
  tags                = local.common_tags


  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.key == "jump" ? azurerm_public_ip.jump.id : null
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each              = var.subnets
  name                  = "vm-${local.name_prefix}-${each.key}"
  location              = azurerm_resource_group.main["compute"].location
  resource_group_name   = azurerm_resource_group.main["compute"].name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.main[each.key].id]
  tags                  = local.common_tags

  custom_data = filebase64("${path.module}/cloud-init/${each.key}.yaml")


  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  os_disk {
    name                 = "osdisk-${local.name_prefix}-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = local.vm_image.publisher
    offer     = local.vm_image.offer
    sku       = local.vm_image.sku
    version   = local.vm_image.version
  }

}


resource "azurerm_public_ip" "jump" {
  name                = "pip-${var.name_prefix}-jump"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_network_interface" "main" {
  for_each            = var.subnet_ids
  name                = "nic-${var.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags


  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_ids[each.key]
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = each.key == "jump" ? azurerm_public_ip.jump.id : null
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  for_each              = var.subnet_ids
  name                  = "vm-${var.name_prefix}-${each.key}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.main[each.key].id]
  tags                  = var.tags

  custom_data = filebase64("${path.module}/cloud-init/${each.key}.yaml")


  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    name                 = "osdisk-${var.name_prefix}-${each.key}"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }
}


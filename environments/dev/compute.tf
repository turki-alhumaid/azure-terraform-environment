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


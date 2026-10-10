resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.name_prefix}-core"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags

}

resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                 = "snet-${var.name_prefix}-${each.key}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]

}

resource "azurerm_network_security_group" "main" {
  for_each = var.subnets

  name                = "nsg-${var.name_prefix}-${each.key}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id

}
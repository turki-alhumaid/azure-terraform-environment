resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.name_prefix}-core"
  location            = azurerm_resource_group.main["network"].location
  resource_group_name = azurerm_resource_group.main["network"].name
  address_space       = var.vnet_address_space
  tags                = local.common_tags

}

resource "azurerm_subnet" "main" {
  for_each = var.subnets

  name                 = "snet-${local.name_prefix}-${each.key}"
  resource_group_name  = azurerm_resource_group.main["network"].name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [each.value]

}

resource "azurerm_network_security_group" "main" {
  for_each = var.subnets

  name                = "nsg-${local.name_prefix}-${each.key}"
  location            = azurerm_resource_group.main["network"].location
  resource_group_name = azurerm_resource_group.main["network"].name
  tags                = local.common_tags

}

resource "azurerm_subnet_network_security_group_association" "main" {
  for_each = var.subnets

  subnet_id                 = azurerm_subnet.main[each.key].id
  network_security_group_id = azurerm_network_security_group.main[each.key].id

}
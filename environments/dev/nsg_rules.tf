resource "azurerm_network_security_rule" "ssh_admin" {
  name                        = "allow-ssh-admin"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = var.admin_source_cidr
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main["network"].name
  network_security_group_name = azurerm_network_security_group.main["jump"].name
}

resource "azurerm_network_security_rule" "app_ssh_from_jump" {
  name                        = "allow-ssh-from-jump"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.main["jump"].address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main["network"].name
  network_security_group_name = azurerm_network_security_group.main["app"].name
}

resource "azurerm_network_security_rule" "data_ssh_from_jump" {
  name                        = "allow-ssh-from-jump"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = azurerm_subnet.main["jump"].address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main["network"].name
  network_security_group_name = azurerm_network_security_group.main["data"].name
}

resource "azurerm_network_security_rule" "deny_vnet_inbound" {
  for_each = var.subnets

  name                        = "deny-vnet-inbound"
  priority                    = 4000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "VirtualNetwork"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.main["network"].name
  network_security_group_name = azurerm_network_security_group.main[each.key].name
}
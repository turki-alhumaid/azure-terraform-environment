resource "azurerm_resource_group" "main" {
  for_each = toset(["network", "compute"])


  name     = "rg-${local.name_prefix}-${each.key}"
  location = var.location
  tags     = local.common_tags
}

module "network" {
  source              = "../../modules/network"
  resource_group_name = azurerm_resource_group.main["network"].name
  location            = azurerm_resource_group.main["network"].location
  vnet_address_space  = var.vnet_address_space
  subnets             = var.subnets
  admin_source_cidr   = var.admin_source_cidr
  tags                = local.common_tags
  name_prefix         = local.name_prefix
}
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

module "compute" {
  source              = "../../modules/compute"
  resource_group_name = azurerm_resource_group.main["compute"].name
  location            = azurerm_resource_group.main["compute"].location
  name_prefix         = local.name_prefix
  ssh_public_key      = file(var.ssh_public_key_path)
  admin_username      = var.admin_username
  tags                = local.common_tags
  vm_size             = var.vm_size
  vm_image            = local.vm_image
  subnet_ids          = module.network.subnet_ids
}

module "governance" {
  source             = "../../modules/governance"
  name_prefix        = local.name_prefix
  allowed_locations  = [var.location]
  required_tags      = var.required_tags
  teams              = var.teams
  resource_group_ids = { for key, rg in azurerm_resource_group.main : key => rg.id }
}
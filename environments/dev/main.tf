resource "azurerm_resource_group" "main" {
  for_each = toset(["network", "compute"])


  name     = "rg-${local.name_prefix}-${each.key}"
  location = var.location
  tags     = local.common_tags
}
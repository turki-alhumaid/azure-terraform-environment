locals {
  location_policies = {
    resources       = "Allowed locations"
    resource-groups = "Allowed locations for resource groups"
  }
}

data "azurerm_subscription" "current" {}

data "azurerm_policy_definition" "location" {
  for_each     = local.location_policies
  display_name = each.value
}

resource "azurerm_subscription_policy_assignment" "location" {
  for_each             = local.location_policies
  name                 = "pa-${var.name_prefix}-locations-${each.key}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.location[each.key].id
  display_name         = "${var.name_prefix} allowed locations (${each.key})"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations
    }
  })
}
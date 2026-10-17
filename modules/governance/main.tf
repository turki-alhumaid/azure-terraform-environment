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

data "azurerm_policy_definition" "require_rg_tag" {
  display_name = "Require a tag on resource groups"
}

resource "azurerm_subscription_policy_assignment" "require_rg_tag" {
  for_each             = toset(var.required_tags)
  name                 = "pa-${var.name_prefix}-require-tag-${each.key}"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.require_rg_tag.id
  display_name         = "${var.name_prefix} require tag on resource groups (${each.key})"

  parameters = jsonencode({
    tagName = {
      value = each.key
    }
  })
}

locals {
  role_scopes = merge(var.resource_group_ids, {
    subscription = data.azurerm_subscription.current.id
  })
}

resource "azuread_group" "team" {
  for_each         = var.teams
  display_name     = "grp-${var.name_prefix}-${each.key}"
  description      = "${each.key} team: ${each.value.role} on ${each.value.scope}"
  security_enabled = true
}

resource "azurerm_role_assignment" "team" {
  for_each             = var.teams
  scope                = local.role_scopes[each.value.scope]
  role_definition_name = each.value.role
  principal_id         = azuread_group.team[each.key].object_id
  principal_type       = "Group"
} 
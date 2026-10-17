variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed locations"
  type        = list(string)
}

variable "required_tags" {
  description = "Tag names every resource group must have"
  type        = list(string)
}

variable "teams" {
  description = "Team name to the role and scope key it gets"
  type = map(object({
    role  = string
    scope = string
  }))
}

variable "resource_group_ids" {
  description = "Resource group key to resource group ID"
  type        = map(string)
}
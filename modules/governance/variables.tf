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

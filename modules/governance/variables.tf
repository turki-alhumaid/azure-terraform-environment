variable "name_prefix" {
  description = "Prefix for naming resources"
  type        = string
}

variable "allowed_locations" {
  description = "List of allowed locations"
  type        = list(string)
}


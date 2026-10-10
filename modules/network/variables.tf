variable "resource_group_name" {
  description = "the name of the resource group"
  type        = string
}

variable "location" {
  description = "the location of the resource group"
  type        = string
}

variable "vnet_address_space" {
  description = "the CIDR block for the virtual network"
  type        = list(string)
}

variable "subnets" {
  description = "the names and ip addresses slices for the Vnet"
  type        = map(string)
}

variable "admin_source_cidr" {
  description = "the public ip allowed to SSH into the 'jump' Vm"
  type        = string
}

variable "tags" {
  description = "the tags to apply to the resources"
  type        = map(string)
}

variable "name_prefix" {
  description = "the prefix to use for naming resources"
  type        = string
}
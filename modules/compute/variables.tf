variable "resource_group_name" {
  description = "the name of the resource group"
  type        = string
}

variable "location" {
  description = "the location of the resource group"
  type        = string
}

variable "name_prefix" {
  description = "the prefix to use for naming resources"
  type        = string
}

variable "ssh_public_key" {
  description = "the public key to use for SSH access"
  type        = string
}

variable "admin_username" {
  description = "the username to use for the admin user"
  type        = string
}

variable "tags" {
  description = "the tags to apply to the resources"
  type        = map(string)
}

variable "subnet_ids" {
  description = "the subnets id to use for the resources"
  type        = map(string)
}

variable "vm_size" {
  description = "the size of the virtual machine"
  type        = string
}

variable "vm_image" {
  description = "the image to use for the virtual machine"
  type        = map(string)
}
variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "enviroment must be dev or prod"
  }
}

variable "location" {
  description = "the location of the deployment"
  type        = string

}

variable "company_name" {
  description = "the name of the company"
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
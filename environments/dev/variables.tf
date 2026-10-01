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
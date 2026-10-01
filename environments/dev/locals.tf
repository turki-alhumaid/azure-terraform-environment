locals {
  name_prefix = "${var.company_name}-${var.environment}"

  common_tags = {
    company_name = var.company_name
    enviroment   = var.environment
    managed_by   = "terraform"
  }
}
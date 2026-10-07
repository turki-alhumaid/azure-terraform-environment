locals {
  name_prefix = "${var.company_name}-${var.environment}"

  common_tags = {
    company_name = var.company_name
    environment  = var.environment
    managed_by   = "terraform"
  }

  vm_image = {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
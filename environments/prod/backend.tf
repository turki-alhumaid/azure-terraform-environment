terraform {
  backend "azurerm" {
    resource_group_name  = "rg-az-infra-tfstate"
    storage_account_name = "stazinfratfstate2424"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
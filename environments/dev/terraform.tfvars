environment        = "dev"
location           = "indiasouthcentral"
company_name       = "az-infra"
vnet_address_space = ["10.10.0.0/16"]
subnets = {
  jump = "10.10.1.0/24"
  app  = "10.10.2.0/24"
  data = "10.10.3.0/24"
}

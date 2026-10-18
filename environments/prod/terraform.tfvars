environment        = "prod"
location           = "indiasouthcentral"
company_name       = "az-infra"
vnet_address_space = ["10.20.0.0/16"]
subnets = {
  jump = "10.20.1.0/24"
  app  = "10.20.2.0/24"
  data = "10.20.3.0/24"
}
admin_username      = "turkiadmin"
ssh_public_key_path = "~/.ssh/az-infra-prod.pub"
vm_size             = "Standard_B2ats_v2"

required_tags = ["environment", "managed_by"]

teams = {
  netops   = { role = "Network Contributor", scope = "network" }
  appops   = { role = "Virtual Machine Contributor", scope = "compute" }
  auditors = { role = "Reader", scope = "subscription" }
}

extra_tags = {
  owner       = "platform-team"
  cost_center = "cc-2001"
}
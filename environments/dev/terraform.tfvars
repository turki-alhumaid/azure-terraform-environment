environment        = "dev"
location           = "indiasouthcentral"
company_name       = "az-infra"
vnet_address_space = ["10.10.0.0/16"]
subnets = {
  jump = "10.10.1.0/24"
  app  = "10.10.2.0/24"
  data = "10.10.3.0/24"
}
admin_username      = "turkiadmin"
ssh_public_key_path = "~/.ssh/az-infra-dev.pub"
vm_size             = "Standard_B2ats_v2"

required_tags = ["environment", "managed_by"]

teams = {
  netops   = { role = "Network Contributor", scope = "network" }
  appops   = { role = "Virtual Machine Contributor", scope = "compute" }
  auditors = { role = "Reader", scope = "subscription" }
}

extra_tags = {
  owner       = "platform-team"
  cost_center = "cc-1001"
}

shutdown_time     = "0000"
shutdown_timezone = "Arab Standard Time"
shutdown_enabled  = true
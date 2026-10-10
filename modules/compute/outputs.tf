output "jump_public_ip" {
  description = "The public IP address of the jump VM."
  value       = azurerm_public_ip.jump.ip_address
}

output "private_ip" {
  description = "The private IP addresses of the VMs."
  value       = { for key, v in azurerm_network_interface.main : key => v.private_ip_address }
}
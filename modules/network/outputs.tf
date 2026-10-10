output "subnet_ids" {
  description = "The IDs of the created subnets."
  value       = { for key, subnet in azurerm_subnet.main : key => subnet.id }
}
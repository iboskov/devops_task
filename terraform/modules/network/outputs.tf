output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Virtual network name"
  value       = azurerm_virtual_network.main.name
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = azurerm_subnet.private.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = azurerm_nat_gateway.main.id
}

output "nat_gateway_association_id" {
  description = "NAT Gateway subnet association ID"
  value       = azurerm_subnet_nat_gateway_association.private.id
}

output "private_nsg_association_id" {
  description = "Private NSG subnet association ID"
  value       = azurerm_subnet_network_security_group_association.private.id
}

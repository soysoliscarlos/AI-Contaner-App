output "vnet_id" {
  description = "ID of the virtual network."
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "Name of the virtual network (for Private DNS zone VNet link)."
  value       = azurerm_virtual_network.vnet.name
}

output "container_apps_subnet_id" {
  description = "ID of the subnet used by Container Apps Environment."
  value       = azurerm_subnet.container_apps.id
}

output "private_endpoints_subnet_id" {
  description = "ID of the subnet for private endpoints."
  value       = azurerm_subnet.private_endpoints.id
}

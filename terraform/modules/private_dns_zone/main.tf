# -----------------------------------------------------------------------------
# Private DNS zone and VNet link (for private endpoint resolution).
# -----------------------------------------------------------------------------

resource "azurerm_private_dns_zone" "zone" {
  name                = var.name
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "link" {
  name                  = "link-${var.vnet_name}"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.zone.name
  virtual_network_id    = var.vnet_id
}

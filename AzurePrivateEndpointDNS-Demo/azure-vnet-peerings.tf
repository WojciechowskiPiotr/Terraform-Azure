# App1 to Transit
resource "azurerm_virtual_network_peering" "app1-to-transit-vnet-peering" {
  name                      = "app1-to-transit-vnet-peering"
  remote_virtual_network_id = azurerm_virtual_network.azure-app1-vnet.id
  resource_group_name       = var.lab-rg
  virtual_network_name      = azurerm_virtual_network.azure-transit-vnet.name
}

resource "azurerm_virtual_network_peering" "transit-to-app1-vnet-peering" {
  name                      = "transit-to-app1-vnet-peering"
  remote_virtual_network_id = azurerm_virtual_network.azure-transit-vnet.id
  resource_group_name       = var.lab-rg
  virtual_network_name      = azurerm_virtual_network.azure-app1-vnet.name
}


# App2 to Transit
resource "azurerm_virtual_network_peering" "app2-to-transit-vnet-peering" {
  name                      = "app2-to-transit-vnet-peering"
  remote_virtual_network_id = azurerm_virtual_network.azure-app2-vnet.id
  resource_group_name       = var.lab-rg
  virtual_network_name      = azurerm_virtual_network.azure-transit-vnet.name
}

resource "azurerm_virtual_network_peering" "transit-to-app2-vnet-peering" {
  name                      = "transit-to-app2-vnet-peering"
  remote_virtual_network_id = azurerm_virtual_network.azure-transit-vnet.id
  resource_group_name       = var.lab-rg
  virtual_network_name      = azurerm_virtual_network.azure-app2-vnet.name
}

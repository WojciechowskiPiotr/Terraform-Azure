resource "azurerm_virtual_network" "azure-2tier-app-vnet" {
  address_space       = ["10.100.0.0/20"]
  location            = var.lab-location
  name                = "azure-2tier-app-vnet"
  resource_group_name = var.lab-rg
  tags                = var.tags
}

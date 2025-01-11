resource "azurerm_network_security_group" "allowall-nsg" {
  location            = var.lab-location
  name                = "allowall-nsg"
  resource_group_name = var.lab-rg

}

resource "azurerm_network_security_rule" "allowall-in-nsg-rule" {
  access                      = "Allow"
  direction                   = "Inbound"
  name                        = "allowall-in"
  priority                    = 102
  protocol                    = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  network_security_group_name = azurerm_network_security_group.allowall-nsg.name
  resource_group_name         = var.lab-rg
}

resource "azurerm_network_security_rule" "allowall-out-nsg-rule" {
  access                      = "Allow"
  direction                   = "Outbound"
  name                        = "allowall-out"
  priority                    = 102
  protocol                    = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  network_security_group_name = azurerm_network_security_group.allowall-nsg.name
  resource_group_name         = var.lab-rg
}

# resource "azurerm_subnet_network_security_group_association" "azure-lz-subnet-1" {
#   network_security_group_id = azurerm_network_security_group.allowall-nsg.id
#   subnet_id                 = azurerm_subnet.azure-lz-subnet-1
#
# }

# ##########################
# # Azure VNet
# ##########################

resource "azurerm_subnet" "azure-app-db-subnet-1" {
  name                 = "azure-app-db-subnet-1"
  resource_group_name  = var.lab-rg
  virtual_network_name = azurerm_virtual_network.azure-2tier-app-vnet.name
  address_prefixes     = ["10.100.2.0/24"]
}

# Public IP resource
resource "azurerm_public_ip" "azure-db-vm1-publicip" {
  name                    = "azure-db-vm1-publicip"
  location                = var.lab-location
  resource_group_name     = var.lab-rg
  sku                     = "Standard"
  sku_tier                = "Regional"
  allocation_method       = "Static"
  ddos_protection_mode    = "Disabled"
  idle_timeout_in_minutes = 30
  tags                    = var.tags
}


# NICs
resource "azurerm_network_interface" "azure-db-vm1-nic1" {
  name                = "azure-db-vm1-nic1"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure-app-db-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure-db-vm1-publicip.id
  }
}


# VM-1 definition
resource "azurerm_virtual_machine" "azure-db-vm1" {
  name                = "azure-db-vm1"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  vm_size = "Standard_B2ts_v2"
  network_interface_ids = [
    azurerm_network_interface.azure-db-vm1-nic1.id,
  ]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  primary_network_interface_id     = azurerm_network_interface.azure-db-vm1-nic1.id
  storage_os_disk {
    name              = "azure-db-vm1-disk1"
    create_option     = "FromImage"
    caching           = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    disk_size_gb      = 40
  }
  storage_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  os_profile {
    computer_name  = "azure-db-vm1"
    admin_username = var.username
    admin_password = var.password
    custom_data    = base64encode(file("scripts/db.sh"))
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}

# NSG associated to VNet Subnet
resource "azurerm_subnet_network_security_group_association" "azure-db-subnet-1" {
  network_security_group_id = azurerm_network_security_group.allowall-nsg.id
  subnet_id                 = azurerm_subnet.azure-app-db-subnet-1.id

}

output "azure-db-vm1_mgmt" {
  value = azurerm_public_ip.azure-db-vm1-publicip.ip_address
}

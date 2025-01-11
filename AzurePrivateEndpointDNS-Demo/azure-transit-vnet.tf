# ##########################
# # Azure Landing Zone
# ##########################

# Azure Landing Zone VNet
# Subnet 10.100.0.0/22 for services (VPNGW, ARS)
resource "azurerm_virtual_network" "azure-transit-vnet" {
  address_space       = ["10.100.0.0/22"]
  location            = var.lab-location
  name                = "azure-transit-vnet"
  resource_group_name = var.lab-rg
  tags                = var.tags
}

resource "azurerm_subnet" "azure-transit-vnet-subnet-1" {
  name                 = "azure-transit-vnet-subnet-1"
  resource_group_name  = var.lab-rg
  virtual_network_name = azurerm_virtual_network.azure-transit-vnet.name
  address_prefixes     = ["10.100.0.0/24"]
}

# NSG associated to VLANs
resource "azurerm_subnet_network_security_group_association" "azure-lz-subnet-1" {
  network_security_group_id = azurerm_network_security_group.allowall-nsg.id
  subnet_id                 = azurerm_subnet.azure-transit-vnet-subnet-1.id

}

# ##########
# #  Azure Transit Zone VM
# ##########
#
# Public IP resource
resource "azurerm_public_ip" "azure-transit-vm-publicip" {
  name                    = "azure-transit-vm-publicip"
  location                = var.lab-location
  resource_group_name     = var.lab-rg
  sku                     = "Standard"
  sku_tier                = "Regional"
  allocation_method       = "Static"
  ddos_protection_mode    = "Disabled"
  idle_timeout_in_minutes = 30
  tags                    = var.tags
}

# NIC 1
resource "azurerm_network_interface" "azure-transit-vm-nic1" {
  name                = "azure-transit-vm-nic1"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure-transit-vnet-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure-transit-vm-publicip.id
  }
}

# VM definition in Azure LZ for vSRX management
resource "azurerm_virtual_machine" "azure-transit-vm" {
  name                = "azure-transit-vm"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  vm_size = "Standard_B2ts_v2"
  network_interface_ids = [
    azurerm_network_interface.azure-transit-vm-nic1.id,
  ]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  primary_network_interface_id     = azurerm_network_interface.azure-transit-vm-nic1.id
  storage_os_disk {
    name              = "azure-transit-vm-disk1"
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
    computer_name  = "azure-transit-vm"
    admin_username = var.username
    admin_password = var.password
    # custom_data    = file("./cloudconfig.txt")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}


output "azure-transit-vm_mgmt" {
  value = azurerm_public_ip.azure-transit-vm-publicip.ip_address
}
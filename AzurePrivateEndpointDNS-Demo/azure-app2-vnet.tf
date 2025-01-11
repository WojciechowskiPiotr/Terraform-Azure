terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.108.0"
    }
  }
}
# ##########################
# # Azure Landing Zone
# ##########################

# Azure Landing Zone VNet
# Subnet 10.202.0.0/22 for services (VPNGW, ARS)
resource "azurerm_virtual_network" "azure-app2-vnet" {
  address_space       = ["10.202.0.0/20"]
  location            = var.lab-location
  name                = "azure-app2-vnet"
  resource_group_name = var.lab-rg
  tags                = var.tags
}

resource "azurerm_subnet" "azure-app2-vnet-subnet-1" {
  name                 = "azure-app2-vnet-subnet-1"
  resource_group_name  = var.lab-rg
  virtual_network_name = azurerm_virtual_network.azure-app2-vnet.name
  address_prefixes     = ["10.202.0.0/24"]
}

resource "azurerm_subnet" "azure-app2-vnet-subnet-2" {
  name                 = "azure-app2-vnet-subnet-2"
  resource_group_name  = var.lab-rg
  virtual_network_name = azurerm_virtual_network.azure-app2-vnet.name
  address_prefixes     = ["10.202.1.0/24"]
}

# NSG associated to VLANs
resource "azurerm_subnet_network_security_group_association" "azure-app2-subnet-1" {
  network_security_group_id = azurerm_network_security_group.allowall-nsg.id
  subnet_id                 = azurerm_subnet.azure-app2-vnet-subnet-1.id

}

resource "azurerm_subnet_network_security_group_association" "azure-app2-subnet-2" {
  network_security_group_id = azurerm_network_security_group.allowall-nsg.id
  subnet_id                 = azurerm_subnet.azure-app2-vnet-subnet-2.id

}

resource "random_string" "storageapp2random" {
  length  = 4
  lower   = true
  special = false
  upper   = false
}

resource "azurerm_storage_account" "azure-app2-storage-account" {
  account_replication_type = "LRS"
  account_tier             = "Standard"
  location                 = "Poland Central"
  name                     = "app2storage${random_string.storageapp2random.result}"
  resource_group_name      = var.lab-rg
}

resource "azurerm_private_dns_zone" "azure-app2-privatedns" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.lab-rg
}

resource "azurerm_private_endpoint" "azure-app2-privateendpoint" {
  location            = "Poland Central"
  name                = "azure-app2-privateendpoint"
  resource_group_name = var.lab-rg
  subnet_id           = azurerm_subnet.azure-app2-vnet-subnet-2.id

  private_service_connection {
    name                           = "azure-app2-privateerviceconnection"
    private_connection_resource_id = azurerm_storage_account.azure-app2-storage-account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "azure-app2-dnsgroup"
    private_dns_zone_ids = [azurerm_private_dns_zone.azure-app2-privatedns.id]
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "dns_vnet_lnk_sta" {
  name                  = "lnk-dns-vnet-sta"
  resource_group_name   = var.lab-rg
  private_dns_zone_name = azurerm_private_dns_zone.azure-app2-privatedns.name
  virtual_network_id    = azurerm_virtual_network.azure-app2-vnet.id
}

resource "azurerm_private_dns_a_record" "dns_a_sta" {
  name                = "sta_a_record"
  zone_name           = azurerm_private_dns_zone.azure-app2-privatedns.name
  resource_group_name = var.lab-rg
  ttl                 = 300
  records             = [azurerm_private_endpoint.azure-app2-privateendpoint.private_service_connection.0.private_ip_address]
}

# ##########
# #  Azure App2 VM
# ##########
#
# Public IP resource
resource "azurerm_public_ip" "azure-app2-vm-publicip" {
  name                    = "azure-app2-vm-publicip"
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
resource "azurerm_network_interface" "azure-app2-vm-nic1" {
  name                = "azure-app2-vm-nic1"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.azure-app2-vnet-subnet-1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.azure-app2-vm-publicip.id
  }
}

# VM definition in Azure LZ for vSRX management
resource "azurerm_virtual_machine" "azure-app2-vm" {
  name                = "azure-app2-vm"
  location            = var.lab-location
  resource_group_name = var.lab-rg

  vm_size = "Standard_B2ts_v2"
  network_interface_ids = [
    azurerm_network_interface.azure-app2-vm-nic1.id,
  ]
  delete_os_disk_on_termination    = true
  delete_data_disks_on_termination = true
  primary_network_interface_id     = azurerm_network_interface.azure-app2-vm-nic1.id
  storage_os_disk {
    name              = "azure-app2-vm-disk1"
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
    computer_name  = "azure-app2-vm"
    admin_username = var.username
    admin_password = var.password
    # custom_data    = file("./cloudconfig.txt")
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = var.tags
}


output "azure-app2-vm_mgmt" {
  value = azurerm_public_ip.azure-app2-vm-publicip.ip_address
}

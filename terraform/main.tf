# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=4.0.1"
    }
  }
}

provider "azurerm" {
  subscription_id = "8f624e34-fd16-4152-91b3-77e8a71922de"
  features {}
}

data "azurerm_resource_group" "main" {
  name = "${var.resource_group_name}"
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/22"]
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  tags = "${var.tagging_policy}"
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "main" {
  count              = "${var.number_vms}"
  name                = "${var.prefix}-nic${count.index}"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = "${var.tagging_policy}"
}

data "azurerm_image" "my_image" {
  name                = "${var.packer_image}"
  resource_group_name = "${var.packer_image_rg}"
}

resource "azurerm_linux_virtual_machine" "main" {
  count              			  = "${var.number_vms}"
  name                            = "${var.prefix}-vm${count.index}"
  resource_group_name             = data.azurerm_resource_group.main.name
  location                        = data.azurerm_resource_group.main.location
  size                            = "Standard_D2s_v3"
  admin_username                  = "${var.admin_username}"
  admin_password                  = "${var.admin_password}"
  disable_password_authentication = false
  tags                            = "${var.tagging_policy}"
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  source_image_id = data.azurerm_image.my_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-public-ip"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  allocation_method   = "Static"
  tags = "${var.tagging_policy}"
}

 resource "azurerm_lb" "main" {
   name                = "${var.prefix}-load_balancer"
   location            = data.azurerm_resource_group.main.location
   resource_group_name = data.azurerm_resource_group.main.name

   frontend_ip_configuration {
     name                 = "public_ip"
     public_ip_address_id = azurerm_public_ip.main.id
   }
   tags = "${var.tagging_policy}"
 }

 resource "azurerm_lb_backend_address_pool" "main" {
   loadbalancer_id     = azurerm_lb.main.id
   name                = "${var.prefix}-be-pool"
 }

resource "azurerm_lb_probe" "main" {
  name            = "${var.prefix}-lb-probe"
  loadbalancer_id = azurerm_lb.main.id
  port            = "${var.custom_port}"
}

resource "azurerm_lb_rule" "main" {
  name                           = "${var.prefix}-lb-rule"
  loadbalancer_id                = azurerm_lb.main.id
  protocol                       = "Tcp"
  probe_id                       = azurerm_lb_probe.main.id
  frontend_port                  = "${var.custom_port}"
  backend_port                   = "${var.custom_port}"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.main.id]
  frontend_ip_configuration_name = azurerm_lb.main.frontend_ip_configuration[0].name
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-nsg"
  location            = data.azurerm_resource_group.main.location
  resource_group_name = data.azurerm_resource_group.main.name
  
  security_rule {
    name                       = "deny-internet-access"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
  
  security_rule {
    name                       = "allow-load-balancer"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "${var.custom_port}"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_public_ip.main.ip_address
  }
  
  security_rule {
    name                       = "allow-internal-inbound"
    priority                   = 900
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

    security_rule {
    name                       = "allow-internal-outbound"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

   tags = "${var.tagging_policy}"
}

resource "azurerm_subnet_network_security_group_association" "sample" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_availability_set" "availbility_set" {
   name                         = "${var.prefix}-availbility_set"
   resource_group_name          = data.azurerm_resource_group.main.name
   location                     = data.azurerm_resource_group.main.location
   platform_fault_domain_count  = 2
   platform_update_domain_count = 2
   managed                      = true
   
   tags = "${var.tagging_policy}"
 }

 resource "azurerm_managed_disk" "managed_disk" {
  count              = "${var.number_vms}"
   name                 = "${var.prefix}-datadisk_${count.index}"
   location             = data.azurerm_resource_group.main.location
   resource_group_name  = data.azurerm_resource_group.main.name
   storage_account_type = "Standard_LRS"
   create_option        = "Empty"
   disk_size_gb         = 10

   tags = "${var.tagging_policy}"
 }

resource "azurerm_virtual_machine_data_disk_attachment" "disk_attachment" {
  count              = "${var.number_vms}"
  managed_disk_id    = element(azurerm_managed_disk.managed_disk.*.id, count.index)
  virtual_machine_id = element(azurerm_linux_virtual_machine.main.*.id, count.index)
  lun                = "1"
  caching            = "ReadWrite"
}
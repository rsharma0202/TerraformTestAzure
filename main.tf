terraform {
  backend "azurerm" {
    resource_group_name  = "dxc-mnue-rg-001"
    storage_account_name = "vmdiagstor01"
    container_name       = "terraform-state"
    key                  = "k0ksERHny9wP7DIYAWXpdGtC1WBKPvFCm0J0tgu943WCVc4SqWsrJbnf+qHasKt8lTKIOtux80mwjwVuQgcZgw=="
  }

  required_providers {
    azurerm = {
      # Specify what version of the provider we are going to utilise
      source  = "hashicorp/azurerm"
      version = ">= 2.4.1"
    }
  }
}
provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group - rakeshchipz-RG
resource "azurerm_resource_group" "rg" {
  name     = "rakeshchipz-app01"
  location = "UK South"
}
# Create our Virtual Network - rakeshchipz-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "rakeshchipzvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - rakeshchipzsa
resource "azurerm_storage_account" "rakeshchipzsa" {
  name                     = "rakeshchipzsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "rakeshchipzenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "rakeshchipzvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine - rakeshchipz-VM01
resource "azurerm_virtual_machine" "rakeshchipzvm01" {
  name                  = "rakeshchipzvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "rakeshchipzvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "rakeshchipzvm01"
    admin_username = "rakeshchipz"
    admin_password = "Password123$"
  }
  os_profile_windows_config {
  }
}

###########################################
# Meraki variables
###########################################

# Network 1
variable "network_name_one" {
  default = "vmx_network_one"
}

# Network 2
variable "network_name_two" {
  default = "vmx_network_two"
}

# Organization ID
variable "organization_id" {
  default   = 000000
  sensitive = true
}


###########################################
# Azure variables
###########################################

# Resource zone location (for all RGs, vNET, vMXs (in ARM template))
variable "azurerm_resources_location" {
  default = "uksouth"
}

# First vMX RG name
variable "azurerm_resource_group_one" {
  default = "vmxs_resource_group_one"
}

# Second vMX RG name
variable "azurerm_resource_group_two" {
  default = "vmxs_resource_group_two"
}

# General RG name
variable "azurerm_resource_group_general" {
  default = "resource_group_general"
}

# Virtual network name, supernet address space.
variable "virtual_network" {
  default = {
    name          = "virtual_network"
    address_space = ["10.0.0.0/16"]
  }
}

# Subnet one name, address space
# *Smallest subnet size is /29, as Azure requires used of 5 IPs in a subnet, leaving one spare host IP in /29.
variable "azurerm_subnet_one" {
  default = {
    name          = "subnet_one"
    address_space = ["10.0.1.0/29"]
  }
}

# Subnet two name, address space
# *Smallest subnet size is /29, as Azure requires used of 5 IPs in a subnet, leaving one spare host IP in /29.
variable "azurerm_subnet_two" {
  default = {
    name          = "subnet_two"
    address_space = ["10.0.1.8/29"]
  }
}

# vMX ARM template one parameters variables
variable "vmxARM_one" {
  default = {
    vmName                  = "vmxone"
    applicationResourceName = "vmxoneapp"
    zone                    = "1"
  }
}

# vMX ARM template two parameters variables
variable "vmxARM_two" {
  default = {
    vmName                  = "vmxtwo"
    applicationResourceName = "vmxtwoapp"
    zone                    = "2"
  }
}
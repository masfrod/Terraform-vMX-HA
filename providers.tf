# Both azurerm and meraki providers are required to work.
# Current Terraform script is written & working on the versions provided below.
# Refer to main.tf for env variables / use_cli functionality.  

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>4.1.0"
    }
    meraki = {
      source  = "cisco-open/meraki"
      version = "0.2.11-alpha"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli = true
}
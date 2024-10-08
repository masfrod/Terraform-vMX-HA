##############################################################################################################
# This configuration deploys following resources in your Meraki dashbnoard and Azure tenant:
#    Meraki: 2x Meraki Dashboard networks with claimed vMXs
#    Azure: 2x Azure deployed Meraki vMXs in individual subnets within same vNET 
# Ready for attaching to vWAN / Route Server, or Azure function, etc.
# This is not a Cisco validated design, use at your own discretion. This is a (simpler) authored design by myself with some referencing to the thorough validated design.
# Please reference the Cisco validated design, and refer to the README.md:
# https://github.com/jsterben/cisco_azure_validated_designs/blob/master/terraform_projects/high_availability_meraki_sdwan_and_catalyst_8000v/main.tf 

# See Terraform providers.tf for setting up Azurerm and Meraki providers in code.  
# Azurerm provider is set to `use_cli = true` (requiring you to login to your tenant via admin/service principal via AZ CLI before running script, use `az account show` to verify) and `subscription_id` is pulled from ARM_SUBSCRIPTION_ID environmental variable (as per schema).
# Meraki provider uses `meraki_dashboard_api_key` which is pulled from MERAKI_DASHBOARD_API_KEY environmental variable (as per schema).

# Refer to README.md for more details.

# Author: Max Smithson
# License: GPL-3.0-or-later.
##############################################################################################################



##############################################################################
# Meraki infra
##############################################################################



# 1. Create 2x new networks in Meraki Dashboard. 
# * Change network names and organization_id in variables.tf

resource "meraki_networks" "network_one" {
  name            = var.network_name_one
  organization_id = var.organization_id
  product_types   = ["appliance"]
  time_zone       = "Europe/London"
}

resource "meraki_networks" "network_two" {
  name            = var.network_name_two
  organization_id = var.organization_id
  product_types   = ["appliance"]
  time_zone       = "Europe/London"
}

# 2. Claim vMXs into Meraki networks.
# * This assumes claimed order of vMXs into Organisation already, this can be automated, e.g. meraki_organizations_inventory_claim (Resource)
# * Specified size is small here, adjust if needed.
# * This will claim any free vMX in the inventory of the appropriate size type into the networks already created, with the depends_on for network creation.
# * Network_two claim will be done after network_one due to a potential race condition being hit where same vMX was claimed at once.

resource "meraki_networks_devices_claim_vmx" "network_one" {
  network_id = meraki_networks.network_one.id
  parameters = {
    size       = "small"
    depends_on = [meraki_networks.network_one]
  }
}

resource "meraki_networks_devices_claim_vmx" "network_two" {
  network_id = meraki_networks.network_two.id
  parameters = {
    size = "small"
  }
  depends_on = [meraki_networks.network_two, meraki_networks_devices_claim_vmx.network_one]
}

# 3. Fetch the serials from the vMXs claimed into those two networks. 
# *This is a Data source to fetch this info, and depends_on both networks creation successes

data "meraki_devices" "networks" {
  organization_id = var.organization_id
  network_ids     = [meraki_networks.network_one.id, meraki_networks.network_two.id]
  depends_on      = [meraki_networks_devices_claim_vmx.network_one, meraki_networks_devices_claim_vmx.network_two]
}

# 4. Local variables to tie vmx_device_X to the specific serial in meraki_networks.network_X. 
# * Required for step 5. authentication token

locals {
  vmx_device_one = element(
    tolist([for device in data.meraki_devices.networks.items : device.serial if device.network_id == meraki_networks.network_one.id]),
    0
  )
  vmx_device_two = element(
    tolist([for device in data.meraki_devices.networks.items : device.serial if device.network_id == meraki_networks.network_two.id]),
    0
  )
}

# 5. Retreive vMX authentication token from each network. 
# * Expects a specific serial to be passed, as per previous step.

resource "meraki_devices_appliance_vmx_authentication_token" "network_one" {
  serial = local.vmx_device_one
}

resource "meraki_devices_appliance_vmx_authentication_token" "network_two" {
  serial = local.vmx_device_two
}



##############################################################################
# Azure infra
##############################################################################



# 6. Accept legal terms from marketplace.
# ** ONLY required to be done once. Re-comment/removed afterwards.

# resource "azurerm_marketplace_agreement" "VMXLegalTerms" {
#   publisher = "cisco"
#   offer = "cisco-meraki-vmx"
#   plan = "cisco-meraki-vmx"
# }

# 7. Creates Resource Groups. One RG for each vXM, one RG for other Azure resources (such as vNET). 

resource "azurerm_resource_group" "one" {
  name     = var.azurerm_resource_group_one
  location = var.azurerm_resources_location
  tags = {
    environment = "prod"
    source      = "terraform"
  }
}

resource "azurerm_resource_group" "two" {
  name     = var.azurerm_resource_group_two
  location = var.azurerm_resources_location
  tags = {
    environment = "prod"
    source      = "terraform"
  }
}

resource "azurerm_resource_group" "general" {
  name     = var.azurerm_resource_group_general
  location = var.azurerm_resources_location
  tags = {
    environment = "prod"
    source      = "terraform"
  }
}

# 8. Create Virtual Network in Azure.

resource "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network.name
  location            = var.azurerm_resources_location
  resource_group_name = var.azurerm_resource_group_general
  depends_on          = [azurerm_resource_group.general]
  address_space       = var.virtual_network.address_space
  dns_servers         = ["8.8.8.8", "8.8.4.4"]
}

# 9. Create Subnets. Attached to Virtual Network above.

resource "azurerm_subnet" "one" {
  name                 = var.azurerm_subnet_one.name
  resource_group_name  = var.azurerm_resource_group_general
  virtual_network_name = var.virtual_network.name
  address_prefixes     = var.azurerm_subnet_one.address_space
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.general]
}

resource "azurerm_subnet" "two" {
  name                 = var.azurerm_subnet_two.name
  resource_group_name  = var.azurerm_resource_group_general
  virtual_network_name = var.virtual_network.name
  address_prefixes     = var.azurerm_subnet_two.address_space
  depends_on           = [azurerm_virtual_network.vnet, azurerm_resource_group.general]
}

# 10. vMX Managed Application ARM template deployment, x2. 
# * Different zones for each vMX chosen for redundancy (refer to var.vmxARM_X.zone).
# * ^If you deploy a vMX into an Availability Zone (like the below x2) then you by default get a Standard IP SKU. This blocks inbound traffic by default and is resource locked against the vMX. Therefore, if you must allow traffic initiated inbound direction, then you must select *no* Availability Zone to get a basic SKU (allowing traffic inbound). 
# * These vMXs are being deployed into vNET and subnets created in this main script. If wanting to deploy into existing (import), this would require edits such as; deleting vNET & subnet resources above, removing depends_on vnet/subnet dependancies below, and choosing to import existing infrastructure resources and defining in ARM template. 
# Please ensure vmx ARM template is up-to-date, as checked via Marketplace > vMX creation > enter any information > until the "Review & Create" screen > select "View Automation Template" > download the ARM template. 

resource "azurerm_resource_group_template_deployment" "vmx_one" {
  name                = "vmx_arm_template_one"
  resource_group_name = var.azurerm_resource_group_one
  depends_on          = [azurerm_virtual_network.vnet, azurerm_resource_group.one, azurerm_subnet.one, meraki_devices_appliance_vmx_authentication_token.network_one]
  template_content    = file("./arm_templates/vmx.template.json")
  parameters_content = jsonencode({
    "location" : { "value" : var.azurerm_resources_location },
    "vmName" : { "value" : var.vmxARM_one.vmName },
    "merakiAuthToken" : { "value" : meraki_devices_appliance_vmx_authentication_token.network_one.item.token },
    "zone"                        = { "value" : var.vmxARM_one.zone },
    "virtualNetworkName"          = { "value" : var.virtual_network.name },
    "virtualNetworkNewOrExisting" = { "value" : "existing" },
    "virtualNetworkAddressPrefix" = { "value" : var.virtual_network.address_space[0] },
    "virtualNetworkResourceGroup" = { "value" : var.azurerm_resource_group_general },
    "virtualMachineSize"          = { "value" : "Standard_F4s_v2" },
    "subnetName"                  = { "value" : var.azurerm_subnet_one.name },
    "subnetAddressPrefix"         = { "value" : var.azurerm_subnet_one.address_space[0] },
    "applicationResourceName"     = { "value" : var.vmxARM_one.applicationResourceName },
  })
  deployment_mode = "Incremental"
  debug_level     = "responseContent"
}

resource "azurerm_resource_group_template_deployment" "vmx_two" {
  name                = "vmx-arm-template-two"
  resource_group_name = var.azurerm_resource_group_two
  depends_on          = [azurerm_virtual_network.vnet, azurerm_resource_group.two, azurerm_subnet.two, meraki_devices_appliance_vmx_authentication_token.network_two]
  template_content    = file("./arm_templates/vmx.template.json")
  parameters_content = jsonencode({
    "location" : { "value" : var.azurerm_resources_location },
    "vmName" : { "value" : var.vmxARM_two.vmName },
    "merakiAuthToken" : { "value" : meraki_devices_appliance_vmx_authentication_token.network_two.item.token },
    "zone"                        = { "value" : var.vmxARM_two.zone },
    "virtualNetworkName"          = { "value" : var.virtual_network.name },
    "virtualNetworkNewOrExisting" = { "value" : "existing" },
    "virtualNetworkAddressPrefix" = { "value" : var.virtual_network.address_space[0] },
    "virtualNetworkResourceGroup" = { "value" : var.azurerm_resource_group_general },
    "virtualMachineSize"          = { "value" : "Standard_F4s_v2" },
    "subnetName"                  = { "value" : var.azurerm_subnet_two.name },
    "subnetAddressPrefix"         = { "value" : var.azurerm_subnet_two.address_space[0] },
    "applicationResourceName"     = { "value" : var.vmxARM_two.applicationResourceName },
  })
  deployment_mode = "Incremental"
  debug_level     = "responseContent"
}
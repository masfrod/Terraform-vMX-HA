# Project

This project deploys 2x Meraki vMXs for "readiness" to deploy as a HA pair, with automating their deployment in Meraki and Azure. 
Readiness meaning that this does not attach the vMXs onto a vWAN, Route Server, or some other routing device in which would allow for L3 HA. This is intended to be imported, manually configured, or edited onto the script.

This project was initially meant as a learning resource / fun project, therefore this does not necessarily include some advanced configurations that would work better when at scale / in production environments, and instead with the purpose of automating and keeping it simple. 
Therefore, this avoids Terraform Cloud tenant, Terraform state files live locally, uses Azure tenant or Service Principal login for ease, variables are hard-coded, and environmental variables set which allows for Azure & Meraki API calls and Azure logins.
Production infrastructure should not use this configuraion, and suggested use of Terraform Cloud or similar offering, alongside further advanced configuration / authentication / backup states.

Example
Importing:
`terraform import azurerm_virtual_wan.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/group1/providers/Microsoft.Network/virtualWans/testvwan`
Creating:
`azurerm_virtual_wan`

# Validate Designs

***
For Cisco Validated Design, please see Juan's work and refer to README.md - https://github.com/jsterben/cisco_azure_validated_designs
***

# Pre-reqs

1. Install Terraform. https://developer.hashicorp.com/terraform/install
2. Clone this repository. https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repositor
3. Access to an Azure Tenant, enable Entra ID (with owner role under your account). https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#user-administrator
For further restricted role-based access control to tenant, consider using Service Principal, or even managed identities:
https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal
https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview 
https://developer.hashicorp.com/terraform/enterprise/workspaces/dynamic-provider-credentials/azure-configuration
4. Cisco Meraki dashboard Organisation. https://documentation.meraki.com/General_Administration/Organizations_and_Networks/Creating_a_Dashboard_Account_and_Organization
Claim vMX serials (can do via trial serials too) into Organisation. https://documentation.meraki.com/General_Administration/Inventory_and_Devices/Using_the_Organization_Inventory
5. Use an IDE. Go to project directory, login with Azure via `az login`, and then run Terraform commands.
6. If unfamiliar with Git, and how it can interact with github, see: https://docs.github.com/en/get-started/using-git/about-git


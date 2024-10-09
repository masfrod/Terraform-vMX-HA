# Project

This project deploys 2x Meraki vMXs for "readiness" to deploy in a HA pair within their respective Meraki and Azure constructs. Readiness meaning that this prepares the vMXs for 'HA', but does not setup & peer to a vWAN, Route Server, or some other routing device in which would allow for L3 HA operation. This is intended to be imported, manually configured, or edited onto the script afterwards.

This project is meant as a learning resource/project, therefore this does *not* necessarily include some advanced configurations that would work better when at scale / in production environments, and instead with the purpose of a simplistic automation demo. Please refer to the "Validated Designs" section for advanced configuration. Therefore, this avoids Terraform Cloud tenant, Terraform state files live locally, uses Azure tenant or Service Principal login for ease (for auth), variables are hard-coded, and environmental variables set locally for convenience. Production infrastructure should not use this configuraion, and suggested use of Terraform Cloud or similar offering, alongside further advanced configuration / authentication / backup states.

Example importing statement, for vWAN:  
`terraform import azurerm_virtual_wan.example /subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/group1/providers/Microsoft.Network/virtualWans/testvwan`  

Example azurerm resource schema, for vWAN:  
`azurerm_virtual_wan`  
  
Terraform files:  
- Main.tf file is intended for main Terraform scripting. Primarily outlining what infrastructure is deployed with `resources` or read with `data` source statements.  
- Providers.tf file denotes the Meraki and Azurerm providers used for their respective schemas. The azurerm provider block follows the schema, with the `use_cli` feature requiring you to login with the SP / MI / Tenant for Azure.  
- Outputs.tf file is optional and commented out. When uncommented, you can specify the value output (reference schema) of each infrastructure resource creation / read to the CLI.  
- Variables.tf file is intended to be altered with the prospective parameters used within the `default` map blocks.  
- Tfstate / .terraform.lock.hcl / providers, are not shown for sensitivity. Install Terraform, outline Terraform providers, and ensure providers are installed with a `terraform init`.     

# Validated Designs

***
For Cisco Validated Design, please see Juan's work and refer to README.md - https://github.com/jsterben/cisco_azure_validated_designs  
This Github repository is highly advised to be referred to for advanced usage with Terraform for vMX deployment.
***

# Pre-requisites

1. Install Terraform:  
https://developer.hashicorp.com/terraform/install  
2. Clone this repository:  
https://docs.github.com/en/repositories/creating-and-managing-repositories/cloning-a-repositor  
If unfamiliar with Git, and how it can interact with github, see:  
https://docs.github.com/en/get-started/using-git/about-git  
3. Access to an Azure Tenant, enable Entra ID (with owner role under your account):  
https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/permissions-reference#user-administrator  
For further restricted role-based access control (RBAC) to tenant, consider using Service Principal, or even managed identities:  
https://learn.microsoft.com/en-us/entra/identity-platform/howto-create-service-principal-portal  
https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview   
https://developer.hashicorp.com/terraform/enterprise/workspaces/dynamic-provider-credentials/azure-configuration  
4. Cisco Meraki dashboard organisation required:  
https://documentation.meraki.com/General_Administration/Organizations_and_Networks/Creating_a_Dashboard_Account_and_Organization  
Claim vMX serials (can do via trial licenses) into dashboard organisation:  
https://documentation.meraki.com/General_Administration/Inventory_and_Devices/Using_the_Organization_Inventory  
5. Use an IDE. Go to project directory, login with Azure via `az login` (with auth stated above), and then run Terraform commands.
# Landing Zone Azure DevOps Steps

### 1. Create Azure DevOps Project

Example: `tftec-ao-vivo-sp-2024`

### 2. Start the repository in Azure Repos and clone it.

### 3. Upload the base repository to Azure Repo.

### 4. In Azure Pipelines, configure the set of variables with Azure Key Vault.

Go to Library > add Variable group > activate Link secrets from an Azure Key Vault as variables.

Variables group name: `tftec-iac-vars`

Add the target subscription.
Add the Key Vault.

Click Save.

### 5. Configure Service Connection

Click Project settings > Pipelines > Service connections, click on the service connection created when creating the link with Azure Key Vault.

Click edit and change the name to: `tftec-devops`. Click on Verify, select Grant access permissions to all pipelines and save.

### 6. Installing the extension required for Terraform commands in the pipeline.

Access the address: https://marketplace.visualstudio.com/

Search for the extension: **Azure Pipelines Terraform Tasks (Jason Johnson)**

https://marketplace.visualstudio.com/items?itemName=JasonBJohnson.azure-pipelines-tasks-terraform

Install the extension in your project, click **Get it free** > select the Azure DevOps organization and install it.

### 7. Create the infrastructure deployment pipeline with Terraform.

Pipelines > New pipeline > Azure Repos Git > <repo_name> > Existing Azure Pipelines YAML file > Branch main > path **/02-Create-ADO-Pipelines/cicd/deploy-infra.yml** > continue > save.
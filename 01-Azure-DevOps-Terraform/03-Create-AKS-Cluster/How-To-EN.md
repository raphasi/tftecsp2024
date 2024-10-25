This repository is part of the presentation **"TFTEC AO VIVO EM SÃO PAULO 2024"**. For more information about the event, please visit [**here**](https://www.tftec.com.br/tftecaovivo-2024/).

# Deploying resources using Terraform (IaC)

Before deploying resources via Terraform IaC, you need to prepare the environment:

1. Landing Zone Terraform Creation Steps.

- [Landing Zone Terraform Creation Steps - Linux Way](https://github.com/asilvajunior/tftec-terraform-aovivo-24-iac/blob/main/01-Azure-Landing-Zone/Landing_Zone_IAC_LNX.txt)
- [Landing Zone Terraform Creation Steps - Windows Way](https://github.com/asilvajunior/tftec-terraform-aovivo-24-iac/blob/main/01-Azure-Landing-Zone/Landing_Zone_IAC_WIN.txt)

2. Landing Zone for Azure DevOps Creation Steps.

- [Landing Zone Azure DevOps Steps](https://github.com/asilvajunior/tftec-terraform-aovivo-24-iac/blob/main/02-Create-ADO-Pipelines/Landing_Zone_ADO.txt)

After that, make sure to make the necessary changes to the variables file to be deployed for this project:

- [Environment variables for the project](https://github.com/asilvajunior/tftec-terraform-aovivo-24-iac/blob/main/03-Create-AKS-Cluster/stacks/env/aovivo-sp-24/aovivosp24.tfvars)




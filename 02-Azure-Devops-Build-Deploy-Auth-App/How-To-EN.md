This repository is part of the presentation **"TFTEC AO VIVO EM SÃO PAULO 2024"**. For more information about the event, please visit [**here**](https://www.tftec.com.br/tftecaovivo-2024/).

# Pre-requisites

1. Azure Cloud Subscription
2. Azure Devops
3. Course Github Repositories
4. Basic infrastructure created in the previous lab: Azure Kubernetes Service with Azure DevOps and Terraform
5. Azure CLI
6. Kubernetes kubectl tool 

### 1. Fork Course Github Repositories

- [TFTEC Microservice app with Azure DevOps](https://github.com/asilvajunior/tftec-terraform-aovivo-24-app)

### 2. Create the Microservice repository

Create a new repository in the training project with the suggested name: `tftec-app`.

### 3. Upload the base repository to Azure Repo.

### 4. In Azure Pipelines, configure the set of variables.

Go to Pipeline > Library and add Variable group:

Variable group name: `tftec-app-vars`

| **Variable**           | **Value**                                |
|------------------------|------------------------------------------|
| dockerfilePath          | docker/Dockerfile                         |
| HelmRepoName           | helm-chart/ao-vivo-sp-24                 |
| imageRepository        | image/ao-vivo-sp-24/tftec-app            |
| tag                    | $(Build.BuildId)                         |

### 5. Configure Service Connection

Click Project settings > Pipelines > Service connections > New service connection.

**Create the Kubernetes service connection:**

Select Kubernetes > next > select the subscription.

For Service connection name: `tftec-kubernetes`

Check Grant access permission to all pipelines and save.

**Crie a service connection do Azure Container Registry:**

Selecione Docker Registry > next > Azure Container Registry.

Authentication Type: `Service Principal` > selecione a assinatura.

Service connection name: `tftec-registry`

Check Grant access permission to all pipelines and save.

### 6. Make the necessary adjustments to the build and deploy pipelines

**Build pipeline:**

Access the yaml file and make changes according to your environment in the settings marked with `MODIFICAR`.

**Build pipeline:**

Access the yaml file and make changes according to your environment in the settings marked with `MODIFICAR`.

### 6. Create the microservice build and deploy pipelines

**Build pipeline:**

Pipelines > New pipeline > Azure Repos Git > <repo_name> > Existing Azure Pipelines YAML file > Branch main > path /cicd/stages/stages-build.yml > continue > rename to `tftec-app-build` > save.

**Deploy pipeline:**

Pipelines > New pipeline > Azure Repos Git > <repo_name> > Existing Azure Pipelines YAML file > Branch main > path /cicd/stages/stages-deploy.yml > continue > rename to `tftec-app-deploy` > save.

### 7. Building and deploying the microservice

Run the `tftec-app-build` build pipeline after success, collect build release information from Azure Container Registry, `image` and `chart`.

With the information in hand, edit the build information in the `stages-deploy.yml` pipeline, save it, and monitor the pipeline execution. If the pipeline is not triggered automatically, go to pipelines and manually run the pipeline `tftec-app-deploy`.

Example:

- **imageTag**: 'latest'
- **chartVersion**: '657'

### 9. Cheque a implatanção do microservico no cluster AKS

Access the AKS cluster via the Azure portal, click connect, select Azure CLI and follow the commands to log in, set up the subscription and download the credentials.

Test connectivity and list the nodes in your cluster:

```bash
kubectl get nodes
```

Confirm that the microservice objects have been created and are running perfectly.

```bash
kubectl get deployments
```

```bash
kubectl get services
```

```bash
kubectl get secrets
```

```bash
kubectl get pods 
```

---

>NOTE: If you do not have Azure CLO and kubectl installed on your machine, follow these steps:

**Modo Linux**

1 - Download and install azcli

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

2 - Download and install Kubectl

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Install kubectl:

```bash
sudo apt-get update
sudo apt-get install -y kubectl
```

Verify the installation:

```bash
kubectl version --client
```

---

**Modo Windows**

1 - Download and install azcli

```powershell
https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli
```

```powershell
2 - Download and install Kubectl (chocolatey)
https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

Install Chocolatey (if it is not already installed). Open PowerShell as Administrator and run the command:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Install kubectl with Chocolatey:

```powershell
choco install kubernetes-cli -y
```

Verify the installation:

```powershell
kubectl version --client
```

---

**Modo Mac**

Install Brew (if it is not already installed). Open terminal as Administrator and run the command:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

1 - Install Azure CLI

```bash
brew update && brew install azure-cli
```

2 - Install kubectl with Brew

```bash
brew install kubectl
```
Verify the installation:

```bash
kubectl version --client
```

---

- **Important Note:** Please access this repository and FORK it and use them during the course.

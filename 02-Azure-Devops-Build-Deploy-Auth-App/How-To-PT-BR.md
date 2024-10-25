Este repositório faz parte da apresentação **"TFTEC AO VIVO EM SÃO PAULO 2024"**. Para mais informações sobre o evento, acesse [**aqui**](https://www.tftec.com.br/tftecaovivo-2024/).

# Pré-requisitos

1. Assinatura do Azure Cloud
2. Azure Devops
3. Curso Repositórios Github
4. Infraestrutura básica criada no laboratório anterior: Azure Kubernetes Service com Azure DevOps e Terraform
5. Azure CLI
6. Ferramenta Kubernetes kubectl

### 1. Fork do Repositórios Github

Faça o fork do repositório da aplicação.

### 2. Crie o repositório Microservice no Azure Devops

Crie um novo repositório no projeto de treinamento com o nome sugerido: `tftec-app`.

### 3. Carregue o repositório base no Azure Repos.

### 4. No Azure Pipelines, configure o conjunto de variáveis.

Vá para Pipeline > Biblioteca e adicione Grupo de variáveis:

Nome do grupo de variáveis: `tftec-app-vars`

Nome do grupo de variáveis: `tftec-app-vars`

| **Variável**           | **Valor**                                |
|------------------------|------------------------------------------|
| dockerfilePath          | docker/Dockerfile                         |
| HelmRepoName           | helm-chart/ao-vivo-sp-24                 |
| imageRepository        | image/ao-vivo-sp-24/tftec-app            |
| tag                    | $(Build.BuildId)                         |

### 5. Configurar conexão de serviço

Clique em Configurações do projeto > Pipelines > Conexões de serviço > Nova conexão de serviço.

**Criar a conexão de serviço do Kubernetes:**

Selecione Kubernetes > próximo > selecione a assinatura.

Para Nome da conexão de serviço: `tftec-kubernetes`

Marque Conceder permissão de acesso a todos os pipelines e salve.

**Criar uma conexão de serviço do Azure Container Registry:**

Selecione Docker Registry > próximo > Azure Container Registry.

Tipo de autenticação: `Service Principal` > selecione uma assinatura.

Nome da conexão de serviço: `tftec-registry`

Marque Conceder permissão de acesso a todos os pipelines e salve.

### 6. Faça os ajustes necessários nos pipelines de build e deploy

**Build pipeline:**

Acesse o arquivo yaml e faça as alterações de acordo com seu ambiente nas configurações marcadas com `MODIFICAR`.

**Build pipeline:**

Acesse o arquivo yaml e faça as alterações de acordo com seu ambiente nas configurações marcadas com `MODIFICAR`.

### 6. Crie os pipelines de build e deploy do microsserviço

**Build pipeline:**

Pipelines > Novo pipeline > Azure Repos Git > <repo_name> > Arquivo YAML existente do Azure Pipelines > Ramificação principal > caminho /cicd/stages/stages-build.yml > continuar > renomear para `tftec-app-build` > salvar.

**Implementar pipeline:**

Pipelines > Novo pipeline > Azure Repos Git > <repo_name> > Arquivo YAML existente do Azure Pipelines > Branch main > caminho /cicd/stages/stages-deploy.yml > continuar > renomear para `tftec-app-deploy` > salvar.

### 7. Construindo e implantando o microsserviço

Execute o pipeline de build `tftec-app-build` após o sucesso, colete informações de versão do build do Azure Container Registry, `image` e `chart`.

Com as informações em mãos, edite as informações do build no pipeline `stages-deploy.yml`, salve-as e monitore a execução do pipeline. Se o pipeline não for disparado automaticamente, vá para pipelines e execute manualmente o pipeline `tftec-app-deploy`.

Exemplo:

- **imageTag**: 'latest'
- **chartVersion**: '657'

### 9. Verifique a implantação do microsserviço no cluster AKS

Acesse o cluster AKS pelo portal do Azure, clique em conectar, selecione Azure CLI e siga os comandos para efetuar login, configurar a assinatura e baixar as credenciais.

Teste a conectividade e liste os nós do seu cluster:

```bash
kubectl get nodes
```

Confirme se os objetos de microsserviço foram criados e estão funcionando perfeitamente.

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

>NOTA: Se você não tiver o Azure CLI e o kubectl instalados em sua máquina, siga estas etapas:

**Linux Way**

1 - Baixe e instale o az cli

```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

2 - Baixe e instale o Kubectl

```bash
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Instalar o kubectl:

```bash
sudo apt-get update
sudo apt-get install -y kubectl
```

Verifique a instalação

```bash
kubectl version --client
```

---

**Windows Way**

1 - Instalar o Azure CLI

```powershell
https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli
```

2 - Baixe e instale o Kubectl (chocolatey)

```powershell
https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/
```

instalar Chocolatey (se ainda não estiver instalado). Abra o PowerShell como administrador e execute o comando:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
```

Instalar kubectl com Chocolatey:

```powershell
choco install kubernetes-cli -y
```

Verifique a instalação

```powershell
kubectl version --client
```

---

**Mac Way**

Instale o Brew (se ainda não estiver instalado).

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

1 - Instalar o Azure CLI

```bash
brew update && brew install azure-cli
```

2 - Instale o kubectl com o Brew

```bash
brew install kubectl
```

Verifique a instalação

```bash
kubectl version --client
```

---

- **Nota importante:** Acesse este repositório, faça um FORK e use-o durante o curso.

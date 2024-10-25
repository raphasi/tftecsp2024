# Etapas do Azure DevOps da Landing Zone

### 1. Crie o projeto do Azure DevOps

Exemplo: `tftec-ao-vivo-sp-2024`

### 2. Inicie o repositório no Azure Repos e clone-o.

### 3. Carregue o repositório base no Azure Repo.

### 4. No Azure Pipelines, configure o conjunto de variáveis ​​com o Azure Key Vault.

Vá para Biblioteca > adicionar grupo de variáveis ​​> ativar segredos de link de um Azure Key Vault como variáveis.

Nome do grupo de variáveis: `tftec-iac-vars`

Adicione a assinatura de destino.
Adicione o Key Vault.

Clique em Salvar.

### 5. Configurar conexão de serviço

Clique em Configurações do projeto > Pipelines > Conexões de serviço, clique na conexão de serviço criada ao criar o link com o Azure Key Vault.

Clique em editar e altere o nome para: `tftec-devops`. Clique em Verificar, selecione Conceder permissões de acesso a todos os pipelines e salve.

### 6. Instalando a extensão necessária para os comandos do Terraform no pipeline.

Acesse o endereço: https://marketplace.visualstudio.com/

Pesquise a extensão: **Azure Pipelines Terraform Tasks (Jason Johnson)**

https://marketplace.visualstudio.com/items?itemName=JasonBJohnson.azure-pipelines-tasks-terraform

Instale a extensão no seu projeto, clique em **Obtenha gratuitamente** > selecione a organização Azure DevOps e instale-a.

### 7. Crie o pipeline de implantação de infraestrutura com o Terraform.

Pipelines > Novo pipeline > Azure Repos Git > <repo_name> > Arquivo YAML existente do Azure Pipelines > Branch main > caminho **/02-Create-ADO-Pipelines/cicd/deploy-infra.yml** > continue > salve.
# Etapas de criação do Landing Zone Terraform

## Variáveis

### Modo Windows:

### A assinatura do Azure de destino
```powershell
$env:ARM_SUBSCRIPTION_ID=""
```

### O nome do grupo de recursos onde a conta de armazenamento para o backend deve ser criada
```powershell
$env:TF_BACKEND_RESOURCE_GROUP="rg-tftec-terraform-tfstate"
```

### A região onde o grupo de recursos para o backend deve ser criado
```powershell
$env:TF_BACKEND_LOCATION="brazilsouth"
```

### O nome da conta de armazenamento para o backend
```powershell
$env:TF_BACKEND_STORAGE_ACCOUNT="tftec24aovivo"
```

### O nome do contêiner da conta de armazenamento para o backend
```powershell
$env:TF_BACKEND_CONTAINER="tfstate"
```

### O nome do blob do contêiner da conta de armazenamento para o backend
```powershell
$env:TF_BACKEND_KEY="tfstate"
```

### Nome do Key Vault
```powershell
$env:KEY_VAULT_NAME="kv-tftec24aovivo"
```

### ID do locatário
```powershell
$env:ARM_TENANT_ID=""
```

### Chave de acesso do backend da conta de armazenamento para o Terraform
```powershell
$env:ACCESS_KEY=$(az storage account keys list --resource-group $env:TF_BACKEND_RESOURCE_GROUP --account-name $env:TF_BACKEND_STORAGE_ACCOUNT --query "[0].value" --output tsv)
```

### Login usando o código do dispositivo
```powershell
az login --use-device-code
```

### Crie o grupo de recursos
```powershell
az group create --name $env:TF_BACKEND_RESOURCE_GROUP --location $env:TF_BACKEND_LOCATION
```

### Crie a conta de armazenamento
```powershell
az storage account create --resource-group $env:TF_BACKEND_RESOURCE_GROUP --name $env:TF_BACKEND_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob --location $env:TF_BACKEND_LOCATION
```

### Crie o contêiner de blob
```powershell
az storage container create --name $env:TF_BACKEND_CONTAINER --account-name $env:TF_BACKEND_STORAGE_ACCOUNT
```

### Crie o Key Vault
```powershell
az keyvault create --name $env:KEY_VAULT_NAME --resource-group $env:TF_BACKEND_RESOURCE_GROUP --location $env:TF_BACKEND_LOCATION --enable-rbac-authorization $false
```

### Garanta o acesso ao Key Vault
```powershell
az keyvault set-policy --name $env:KEY_VAULT_NAME --object-id $env:ARM_CLIENT_ID --secret-permissions get list --key-permissions get list --certificate-permissions get list
```

### Crie segredos para todas as variáveis ​​de ambiente no Key Vault
```powershell
az keyvault secret set --nome-do-cofre $env:NOME_DO_COFRE_DE_CHAVE --nome "CONTA-DE-ARMAZENAMENTO-DE-BACKEND-TF" --valor $env:CONTA_DE_ARMAZENAMENTO_DE_BACKEND_TF
conjunto de segredos do az keyvault --nome-do-cofre $env:NOME_DO_COFRE_DE_CHAVE --nome "CHAVE-DE-BACKEND-TF" --valor $env:NOME_DO_COFRE_DE_CHAVE
conjunto de segredos do az keyvault --nome-do-cofre $env:NOME_DO_COFRE_DE_CHAVE --nome "ID-DO-TENENTE-DA-ARMA" --valor $env:ID_DO_TENENTE_DA-ARMA
conjunto de segredos do az keyvault --nome-do-cofre $env:NOME_DO_COFRE_DE_CHAVE --nome "ID-DA-ARM-ASSINATURA" --valor $env:ID_DA_ARM_ASSINATURA
conjunto de segredos do az keyvault --nome-do-cofre $env:NOME_DO_COFRE_DE_CHAVE --nome "GRUPO-DE-RECURSOS-DE-BACKEND-TF" --valor $env:TF_BACKEND_RESOURCE_GROUP
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "TF-BACKEND-CONTAINER" --value $env:TF_BACKEND_CONTAINER
```

### Inicialização do Terraform com configuração de backend
```powershell
terraform init -reconfigure `
-backend-config "resource_group_name=$env:TF_BACKEND_RESOURCE_GROUP" `
-backend-config "storage_account_name=$env:TF_BACKEND_STORAGE_ACCOUNT" `
-backend-config "container_name=$env:TF_BACKEND_CONTAINER" `
-backend-config "key=$env:TF_BACKEND_KEY" `
-backend-config "subscription_id=$env:ARM_SUBSCRIPTION_ID" `
-backend-config "chave_de_acesso=$env:CHAVE_DE_ACESSO"
```
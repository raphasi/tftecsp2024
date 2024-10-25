# Etapas de criação do Landing Zone Terraform

## Variáveis

### Maneira Linux:

### A assinatura do Azure de destino
```bash
export ARM_SUBSCRIPTION_ID=

### O nome do grupo de recursos onde a conta de armazenamento para o backend deve ser criada
```bash
export TF_BACKEND_RESOURCE_GROUP=rg-tftec-terraform-tfstate
```

### A região onde o grupo de recursos para o backend deve ser criado
```bash
export TF_BACKEND_LOCATION=eastus
```

### O nome da conta de armazenamento para o backend
```bash
export TF_BACKEND_STORAGE_ACCOUNT=tftec24aovivosp
```

### O nome do contêiner da conta de armazenamento para o backend
```bash
export TF_BACKEND_CONTAINER=tfstate
```

### O nome do blob do contêiner da conta de armazenamento para o backend
```bash
export TF_BACKEND_KEY=tfstate
```

### Nome do cofre de chaves
```bash
export KEY_VAULT_NAME=kv-tftecaovivo24
```

### ID do locatário
```bash
export ARM_TENANT_ID=
```

### Chave de acesso do backend da conta de armazenamento Terraform (Depois de já ter criado o armazenamento!)
```bash
export ACCESS_KEY=$(az storage account keys list --resource-group $TF_BACKEND_RESOURCE_GROUP --account-name $TF_BACKEND_STORAGE_ACCOUNT --query "[0].value" --output tsv)
```

---

## Etapas

### 1. Efetue login usando o código do dispositivo
```bash
az login --use-device-code
```

### 2. Crie um grupo de recursos
```bash
az group create --name $TF_BACKEND_RESOURCE_GROUP --location $TF_BACKEND_LOCATION
```

### 3. Crie uma conta de armazenamento
```bash
az storage account create --resource-group $TF_BACKEND_RESOURCE_GROUP --name $TF_BACKEND_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob --location $TF_BACKEND_LOCATION
```

### 4. Crie um blob de contêiner
```bash
az storage container create --name $TF_BACKEND_CONTAINER --account-name $TF_BACKEND_STORAGE_ACCOUNT
```

### 5. Crie um cofre de chaves
```bash
az keyvault create --name $KEY_VAULT_NAME --resource-group $TF_BACKEND_RESOURCE_GROUP --location $TF_BACKEND_LOCATION --enable-rbac-authorization false
```

### 6. Crie segredos para todas as variáveis ​​de ambiente no cofre de chaves
```bash
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-STORAGE-ACCOUNT" --value $TF_BACKEND_STORAGE_ACCOUNT
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-KEY" --value $TF_BACKEND_KEY
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "ARM-TENANT-ID" --value $ARM_TENANT_ID
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "ARM-SUBSCRIPTION-ID" --value $ARM_SUBSCRIPTION_ID
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-RESOURCE-GROUP" --value $TF_BACKEND_RESOURCE_GROUP
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-CONTAINER" --value $TF_BACKEND_CONTAINER
```

### 7. Inicialização do Terraform com configuração de backend
```bash
terraform init -reconfigure \
-backend-config "resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
-backend-config "storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
-backend-config "nome_do_container=$TF_BACKEND_CONTAINER" \
-backend-config "chave=$TF_BACKEND_KEY" \
-backend-config "id_da_assinatura=$ARM_SUBSCRIPTION_ID" \
-backend-config "chave_de_acesso=$ACCESS_KEY"
```
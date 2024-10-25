# Landing Zone Terraform Creation Steps

## Variables

### Linux way:

### The target azure subscription
```bash
export ARM_SUBSCRIPTION_ID=
```

### The name of the resource group where the storage account for the backend should be created
```bash
export TF_BACKEND_RESOURCE_GROUP=rg-tftec-terraform-tfstate
```

### The region where the resource group for the backend should be created
```bash
export TF_BACKEND_LOCATION=eastus
```

### The name of the storage account for the backend
```bash 
export TF_BACKEND_STORAGE_ACCOUNT=tftec24aovivosp
```

### The name of the storage account container for the backend
```bash
export TF_BACKEND_CONTAINER=tfstate
```

### The name of the storage account container blob for the backend
```bash
export TF_BACKEND_KEY=tfstate
```

### Key vault name
```bash
export KEY_VAULT_NAME=kv-tftecaovivo24
```

### Tenant ID
```bash
export ARM_TENANT_ID=
```

### Access key from storage account backend Terraform (After you have already created the storage!)
```bash
export ACCESS_KEY=$(az storage account keys list --resource-group $TF_BACKEND_RESOURCE_GROUP --account-name $TF_BACKEND_STORAGE_ACCOUNT --query "[0].value" --output tsv)
```

---

## Steps

### 1. Log in using the device code
```bash
az login --use-device-code
```

### 2. Create a resource group
```bash
az group create --name $TF_BACKEND_RESOURCE_GROUP --location $TF_BACKEND_LOCATION
```

### 3. Create a storage account
```bash
az storage account create --resource-group $TF_BACKEND_RESOURCE_GROUP --name $TF_BACKEND_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob --location $TF_BACKEND_LOCATION
```

### 4. Create a container blob
```bash
az storage container create --name $TF_BACKEND_CONTAINER --account-name $TF_BACKEND_STORAGE_ACCOUNT
```

### 5. Create a key vault
```bash
az keyvault create --name $KEY_VAULT_NAME --resource-group $TF_BACKEND_RESOURCE_GROUP --location $TF_BACKEND_LOCATION --enable-rbac-authorization false
```

### 6. Create secrets for all environment variables in the key vault
```bash
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-STORAGE-ACCOUNT" --value $TF_BACKEND_STORAGE_ACCOUNT
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-KEY" --value $TF_BACKEND_KEY
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "ARM-TENANT-ID" --value $ARM_TENANT_ID
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "ARM-SUBSCRIPTION-ID" --value $ARM_SUBSCRIPTION_ID
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-RESOURCE-GROUP" --value $TF_BACKEND_RESOURCE_GROUP
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "TF-BACKEND-CONTAINER" --value $TF_BACKEND_CONTAINER
```

### 7. Terraform initialization with backend configuration
```bash
terraform init -reconfigure \
  -backend-config "resource_group_name=$TF_BACKEND_RESOURCE_GROUP" \
  -backend-config "storage_account_name=$TF_BACKEND_STORAGE_ACCOUNT" \
  -backend-config "container_name=$TF_BACKEND_CONTAINER" \
  -backend-config "key=$TF_BACKEND_KEY" \
  -backend-config "subscription_id=$ARM_SUBSCRIPTION_ID" \
  -backend-config "access_key=$ACCESS_KEY"
```
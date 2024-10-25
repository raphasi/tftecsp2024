# Landing Zone Terraform Creation Steps

## Variables

### Windows way:

### The target Azure subscription
```powershell
$env:ARM_SUBSCRIPTION_ID=""
```

### The name of the resource group where the storage account for the backend should be created
```powershell
$env:TF_BACKEND_RESOURCE_GROUP="rg-tftec-terraform-tfstate"
```

### The region where the resource group for the backend should be created
```powershell
$env:TF_BACKEND_LOCATION="brazilsouth"
```

### The name of the storage account for the backend
```powershell
$env:TF_BACKEND_STORAGE_ACCOUNT="tftec24aovivo"
```

### The name of the storage account container for the backend
```powershell
$env:TF_BACKEND_CONTAINER="tfstate"
```

### The name of the storage account container blob for the backend
```powershell
$env:TF_BACKEND_KEY="tfstate"
```

### Key Vault name
```powershell
$env:KEY_VAULT_NAME="kv-tftec24aovivo"
```

### Tenant ID
```powershell
$env:ARM_TENANT_ID=""
```

### Access key from the storage account backend for Terraform
```powershell
$env:ACCESS_KEY=$(az storage account keys list --resource-group $env:TF_BACKEND_RESOURCE_GROUP --account-name $env:TF_BACKEND_STORAGE_ACCOUNT --query "[0].value" --output tsv)
```

### Login using device code
```powershell
az login --use-device-code
```

### Create the resource group
```powershell
az group create --name $env:TF_BACKEND_RESOURCE_GROUP --location $env:TF_BACKEND_LOCATION
```

### Create the storage account
```powershell
az storage account create --resource-group $env:TF_BACKEND_RESOURCE_GROUP --name $env:TF_BACKEND_STORAGE_ACCOUNT --sku Standard_LRS --encryption-services blob --location $env:TF_BACKEND_LOCATION
```

### Create the blob container
```powershell
az storage container create --name $env:TF_BACKEND_CONTAINER --account-name $env:TF_BACKEND_STORAGE_ACCOUNT
```

### Create the Key Vault
```powershell
az keyvault create --name $env:KEY_VAULT_NAME --resource-group $env:TF_BACKEND_RESOURCE_GROUP --location $env:TF_BACKEND_LOCATION --enable-rbac-authorization $false
```

### Ensure access to Key Vault
```powershell
az keyvault set-policy --name $env:KEY_VAULT_NAME --object-id $env:ARM_CLIENT_ID --secret-permissions get list --key-permissions get list --certificate-permissions get list
```

### Create secrets for all environment variables in the Key Vault
```powershell
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "TF-BACKEND-STORAGE-ACCOUNT" --value $env:TF_BACKEND_STORAGE_ACCOUNT
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "TF-BACKEND-KEY" --value $env:TF_BACKEND_KEY
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "ARM-TENANT-ID" --value $env:ARM_TENANT_ID
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "ARM-SUBSCRIPTION-ID" --value $env:ARM_SUBSCRIPTION_ID
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "TF-BACKEND-RESOURCE-GROUP" --value $env:TF_BACKEND_RESOURCE_GROUP
az keyvault secret set --vault-name $env:KEY_VAULT_NAME --name "TF-BACKEND-CONTAINER" --value $env:TF_BACKEND_CONTAINER
```

### Terraform initialization with backend configuration
```powershell
terraform init -reconfigure `
  -backend-config "resource_group_name=$env:TF_BACKEND_RESOURCE_GROUP" `
  -backend-config "storage_account_name=$env:TF_BACKEND_STORAGE_ACCOUNT" `
  -backend-config "container_name=$env:TF_BACKEND_CONTAINER" `
  -backend-config "key=$env:TF_BACKEND_KEY" `
  -backend-config "subscription_id=$env:ARM_SUBSCRIPTION_ID" `
  -backend-config "access_key=$env:ACCESS_KEY"
```
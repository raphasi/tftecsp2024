# Imersão TFTEC Azure ao vivo em SP

Esse projeto descreve os principais passos utilizados no nosso treinamento presencial de SP.
Temos como objetivo construir uma infraestrutura completa, simulando um cenário real de uma empresa que tem a necessidade de utilizar diversos recursos do Azure para rodar o seu negócio.

# Estrutura
O desenho de arquitetura informado abaixo mostra alguns detalhes de como está configurada a estrutura da empresa que iremos construir.

![TFTEC Cloud](https://github.com/raphasi/tftecsp2024/blob/main/Diagrama.png "Arquitetura Imersão")

# Estrutura de deploy com Terraform (IaC)

![TFTEC Cloud](https://github.com/raphasi/tftecsp2024/blob/main/Diagrama-IaC.png "Arquitetura IaC")

![TFTEC Cloud](https://github.com/raphasi/tftecsp2024/blob/main/Flow-IaC.png "Arquitetura IaC")

# Estrutura de Build e deploy da aplicação em cluster Azure Kubernetes Services (AKS)

![TFTEC Cloud](https://github.com/raphasi/tftecsp2024/blob/main/Driagrama-Build-Deploy.png "Arquitetura Azure DevOps")

## STEP01 - Criar um Resource Group e estrutura de VNETS e Subnets
1- Script PowerShell para criar estrutura de rede inicial
```cmd
## Script: Criar Landing Zone - TFTEC ao VIVO SP
## Autor: Raphael Andrade
## Data: Setembro/24

# Definir variáveis
$resourceGroupName = "rg-tftecsp-001"
$location01 = "uksouth"
$location02 = "brazilsouth"

# Criar Resource Group
New-AzResourceGroup -Name $resourceGroupName -Location $location01

# Criar VNet Hub e Subnet
$subnetConfigHub = New-AzVirtualNetworkSubnetConfig -Name "sub-srv-001" -AddressPrefix "10.10.1.0/24"
$vnetHub = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location02 -Name "vnet-hub-001" -AddressPrefix "10.10.0.0/16" -Subnet $subnetConfigHub

# Criar NSG Hub e associar à subnet
$nsgHub = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location02 -Name "nsg-hub-001"

# Adicionar regra de entrada para RDP
$nsgHub | Add-AzNetworkSecurityRuleConfig -Name "Allow-RDP-VM-APPs" `
    -Description "Libera acesso RDP para VM-APPs" `
    -Access Allow `
    -Protocol Tcp `
    -Direction Inbound `
    -Priority 200 `
    -SourceAddressPrefix * `
    -SourcePortRange * `
    -DestinationAddressPrefix "10.10.1.4" `
    -DestinationPortRange 3389

# Aplicar as mudanças ao NSG
$nsgHub | Set-AzNetworkSecurityGroup

Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnetHub -Name "sub-srv-001" -AddressPrefix "10.10.1.0/24" -NetworkSecurityGroup $nsgHub
$vnetHub | Set-AzVirtualNetwork

# Criar VNet Spoke e Subnets
$subnetConfigSpoke = @(
    New-AzVirtualNetworkSubnetConfig -Name "sub-web-001" -AddressPrefix "10.11.1.0/24"
    New-AzVirtualNetworkSubnetConfig -Name "sub-aks-001" -AddressPrefix "10.11.2.0/24"
    New-AzVirtualNetworkSubnetConfig -Name "sub-appgw-001" -AddressPrefix "10.11.3.0/24"
    New-AzVirtualNetworkSubnetConfig -Name "sub-vint-001" -AddressPrefix "10.11.4.0/24"
    New-AzVirtualNetworkSubnetConfig -Name "sub-db-001" -AddressPrefix "10.11.5.0/24"
)
$vnetSpoke = New-AzVirtualNetwork -ResourceGroupName $resourceGroupName -Location $location01 -Name "vnet-spk-001" -AddressPrefix "10.11.0.0/16" -Subnet $subnetConfigSpoke

# Criar NSG Spoke e associar às subnets
$nsgSpoke = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location01 -Name "nsg-spk-001"
$subnetsToAssociate = @("sub-web-001", "sub-aks-001", "sub-vint-001", "sub-db-001")
foreach ($subnetName in $subnetsToAssociate) {
    Set-AzVirtualNetworkSubnetConfig -VirtualNetwork $vnetSpoke -Name $subnetName -AddressPrefix ($vnetSpoke.Subnets | Where-Object {$_.Name -eq $subnetName}).AddressPrefix -NetworkSecurityGroup $nsgSpoke
}
$vnetSpoke | Set-AzVirtualNetwork

# Criar peering entre as VNets
Add-AzVirtualNetworkPeering -Name "HubToSpoke" -VirtualNetwork $vnetHub -RemoteVirtualNetworkId $vnetSpoke.Id -AllowForwardedTraffic
Add-AzVirtualNetworkPeering -Name "SpokeToHub" -VirtualNetwork $vnetSpoke -RemoteVirtualNetworkId $vnetHub.Id -AllowForwardedTraffic

# Criar VM Windows
$vmName = "vm-apps"
$vmSize = "Standard_B2s"
$adminUsername = "admin.tftec"
$adminPassword = ConvertTo-SecureString "Partiunuvem@2024" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($adminUsername, $adminPassword)

# Verificar a disponibilidade da imagem
$publisher = "MicrosoftWindowsServer"
$offer = "WindowsServer"
$skus = @("2022-Datacenter", "2022-datacenter-azure-edition")

$availableSku = $null
foreach ($sku in $skus) {
    $availableImage = Get-AzVMImage -Location $location02 -PublisherName $publisher -Offer $offer -Skus $sku -ErrorAction SilentlyContinue
    if ($availableImage) {
        $availableSku = $sku
        break
    }
}

if (-not $availableSku) {
    Write-Error "Não foi possível encontrar uma imagem do Windows Server 2022 disponível na região $location02"
    return
}

$publicIp = New-AzPublicIpAddress -Name "$vmName-pip" -ResourceGroupName $resourceGroupName -Location $location02 -AllocationMethod Static
$nic = New-AzNetworkInterface -Name "$vmName-nic" -ResourceGroupName $resourceGroupName -Location $location02 -SubnetId $vnetHub.Subnets[0].Id -PublicIpAddressId $publicIp.Id

# Definir a configuração da VM
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

# Definir o sistema operacional
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate

# Definir a imagem do sistema operacional
$vmConfig = Set-AzVMSourceImage -VM $vmConfig -PublisherName $publisher -Offer $offer -Skus $availableSku -Version "latest"

# Adicionar a interface de rede
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# Configurar o disco do sistema operacional
$vmConfig = Set-AzVMOSDisk -VM $vmConfig -CreateOption FromImage -StorageAccountType Premium_LRS

# Criar a VM
New-AzVM -ResourceGroupName $resourceGroupName -Location $location02 -VM $vmConfig

# Criar Storage Account PRD
$storageAccountName = "stotftecsp" + (Get-Random -Minimum 100000 -Maximum 999999)
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
                                       -Name $storageAccountName `
                                       -Location $location01 `
                                       -SkuName Standard_LRS `
                                       -Kind StorageV2 `
                                       -AllowBlobPublicAccess $true

# Criar container 'imagens' na Storage Account
$ctx = $storageAccount.Context
New-AzStorageContainer -Name "imagens" -Context $ctx -Permission Blob

Write-Output "Storage Account criada: $storageAccountName"


# Criar Storage Account DEV
$storageAccountName = "stotftecspdev" + (Get-Random -Minimum 100000 -Maximum 999999)
$storageAccount = New-AzStorageAccount -ResourceGroupName $resourceGroupName `
                                       -Name $storageAccountName `
                                       -Location $location01 `
                                       -SkuName Standard_LRS `
                                       -Kind StorageV2 `
                                       -AllowBlobPublicAccess $true

# Criar container 'imagens' na Storage Account com acesso de leitura anônimo para blobs
$ctx = $storageAccount.Context
New-AzStorageContainer -Name "imagens" -Context $ctx -Permission Blob

Write-Output "Storage Account criada: $storageAccountName"
 ```
 

## STEP02 - Deploy dos WebApps
1.0 Criar um App Service Plan:
```cmd
   Nome: appplan-tftec-001
   Operation System: Windows
   Região: uksouth
   SKU: Standard S1
```

1.1 Criar o WebApp do Ingresso
```cmd
   Nome: app-ingresso-tftecxxxx
   Desmarcar "Unique default hostname"
   Runtime Stack: .NET 8
   Operation Sistem: Windows
   Region: uksouth
   Escolher o App Service Plan criado no passo 1.0
```

1.2 Criar o WebApp do Bend (API)
```cmd
   Nome: app-bend-tftecxxxx
   Desmarcar "Unique default hostname"
   Runtime Stack: .NET 8
   Operation Sistem: Windows
   Region: uksouth
   Escolher o App Service Plan criado no passo 1.0
```

1.3 Criar o Webapp do CRM
```cmd 
   Nome: app-crm-tftecxxxx
   Desmarcar "Unique default hostname"
   Runtime Stack: .NET 8
   Operation Sistem: Windows
   Region: uksouth
   Escolher o App Service Plan criado no passo 1.0
 ```

 1.4 Criar o Webapp do Auth
```cmd 
   Nome: app-auth-tftecxxxx
   Desmarcar "Unique default hostname"
   Runtime Stack: .NET 8
   Operation Sistem: Windows
   Region: uksouth
   Escolher o App Service Plan criado no passo 1.0
 ```  
2.0 Baixar pacotes das aplicações:

Aplicação BEND (API)
https://raw.githubusercontent.com/raphasi/tftecsp2024/main/WebApps%20Code/CRM.API.BEND.zip

Aplicação INGRESSO
https://raw.githubusercontent.com/raphasi/tftecsp2024/main/WebApps%20Code/CRM.WebApp.Ingresso.zip

Aplicação CRM
https://raw.githubusercontent.com/raphasi/tftecsp2024/main/WebApps%20Code/CRM.WebApp.Site.zip

Aplicação AUTH 
https://raw.githubusercontent.com/raphasi/tftecsp2024/main/WebApps%20Code/CRM.API.AUTH.zip



2.1 Utilizando o cloudshell, fazer upload dos 4 pacotes.

2.2 Realizar o deploy da aplicação BEND (API) para o WebApp
Abrir o cloudshel e executar o seguinte comando:
```cmd
az webapp deploy --resource-group rg-tftecsp-001 --name app-bend-tftec-dev --src-path CRM.API.BEND.zip
```

2.3 Realizar o deploy da aplicação INGRESSO para o WebApp
Abrir o cloudshel e executar o seguinte comando:
```cmd
az webapp deploy --resource-group rg-tftecsp-001 --name app-ingresso-tftec-dev --src-path CRM.WebApp.Ingresso.zip
```

2.4 Realizar o deploy da aplicação CRM para o WebApp
Abrir o cloudshel e executar o seguinte comando:
```cmd
az webapp deploy --resource-group rg-tftecsp-001 --name app-crm-tftec-dev --src-path CRM.WebApp.Site.zip
```

2.5 Realizar o deploy da aplicação AUTH para o WebApp
Abrir o cloudshel e executar o seguinte comando:
```cmd
az webapp deploy --resource-group rg-tftecsp-001 --name app-auth-tftec-dev --src-path CRM.API.AUTH.zip
```

## STEP03 - Deploy do Azure SQL Database
1.0 Criar um novo SQL Server
```cmd
Nome: srv-sql-tftecxxxxx (usar um nome único)
Location: 
Authentication method: Use SQL authentication   
   user: sqladmin
   pass: Partiunuvem@2024
Allow Azure services and resources to access this server: YES
```
1.1 Instalar o SSMS
```cmd
Acessar o servidor vm-apps e instalar o SQL Management Studio
User: admin.tftec
Pass: Partiunuvem@2024
```
Download do SQL SSMS: https://aka.ms/ssmsfullsetup

Donwload do Database: https://raw.githubusercontent.com/raphasi/tftecsp2024/main/sistema-tftec-db.bacpac

1.2 Importar database aplicação WebSite
```cmd
Abrir o SQL Management Studio
Server Name: Copia o nome do SQL Server criado no passo anterior
Alterar formato de autenticação para SQL Server authentication  
Logar com usuário e senha criados no passo anterior
Importar o database usando a opção de dacpac
*Caso necessário, alterar o nome do database para: sistema-tftec-db
```
1.3 Ajustar SQL Database
```cmd
Ajustar configuração do SQL Database:
   - Compute + Storage: Mudar opção de backup para LRS
```

## STEP04 - Ajuste Connection String
1.0 Configurar conexão BEND x SQL Database
```cmd
Realizar o ajuste da connection string no WebApp BEND
Name: DefaultConnection
Value: Data Source=srv-dbtftecsp-dev.database.windows.net,1433;Initial Catalog=sistema-tftec-db;User ID=sqladmin;Password=Partiunuvem@2024;MultipleActiveResultSets=True;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
*Alterar para o nome do seu banco e validar o usuário e senha
Type: AzureSQL
Deployment slot setting: SIM (checar)
Testar o Swagger validando uma consulta no banco
```

## STEP05 - Deploy Logic App  
1.0 Realizar o deploy do Logic App para update das imagens do WebApp INGRESSO
```cmd
Logic App Tier: Consumption
Resource Group: rg-tftecsp-001
Logic App name: lgapp-img-001
Enable log analytics: NO
```
1.1 Configurar o fluxo para o import das imagens
```cmd
1.0 Configurar o fluxo para importação das imagens
```cmd
Esta Logic App realiza a sincronização de imagens entre um servidor FTP e um Azure Blob Storage.
O fluxo segue a seguinte sequência:
```

1.1 Trigger (Gatilho)
```cmd
Tipo: HTTP Request
Quando uma requisição HTTP é recebida, o fluxo é iniciado
```

1.2 Primeira Ação - Listar Arquivos
```cmd
Nome: List files in folder
Conexão: FTP
Pasta monitorada: /site/wwwroot/wwwroot/assets/img/produto_evento
Função: Lista todos os arquivos presentes na pasta especificada do servidor FTP
```

1.3 Segunda Ação - Loop For Each
```cmd
Nome: For each
Entrada: Resultado da listagem de arquivos
Função: Itera sobre cada arquivo encontrado na pasta
Configuração: 
   - Execução sequencial (uma por vez)
   - Concorrência: 1 repetição
```

1.4 Ações dentro do Loop
```cmd
Primeira ação do loop:
   Nome: Get file content using path
   Função: Obtém o conteúdo do arquivo atual do FTP
   Entrada: Caminho do arquivo atual (item().Path)

Segunda ação do loop:
   Nome: Create blob (V2)
   Função: Cria um novo blob no Azure Storage
   Configuração:
      - Container: container-images
      - Nome do arquivo: Mantém o nome original do arquivo
      - Modo de transferência: Chunked (em partes)
   Executa após: Sucesso na obtenção do conteúdo do arquivo
```

1.5 Conexões necessárias
```cmd
FTP:
   - Tipo: FTP
   - Função: Acesso ao servidor FTP fonte

Azure Blob:
   - Tipo: Azure Blob Storage
   - Função: Armazenamento destino das imagens
```

### Resultado Final
```cmd
Quando executado, o fluxo:
1. Recebe uma chamada HTTP
2. Lista todos os arquivos da pasta de imagens no FTP
3. Para cada arquivo encontrado:
   - Obtém seu conteúdo do FTP
   - Cria uma cópia no container do Blob Storage
4. Mantém sincronizado o repositório de imagens entre FTP e Blob Storage
```

## STEP06 - Deploy Apps Registration para o CRM

1.0 Criar o App Registration CRM01
```cmd
1.0 Criar o App Registration CRM.API
```cmd
Acessar o Azure Portal
Acessar Microsoft Entra ID
App Registrations - New Registration
Nome: CRM.API
Suported account types: Single tenant
Register
```

1.1 Configurar Expose an API
```cmd
Acessar o App Registration criado
Selecionar Expose an API
Set Application ID URI: api://(copie o seu ID)
Add a scope:
   - Scope name: AdminApi
   - Who can consent?: Admins only
   - Admin consent display name: AdminApi
   - Admin consent description: AdminApi
   - State: Enabled
   - Add scope
```

1.2 Configurar App Roles
```cmd
Acessar App roles
New app role:
   Display name: Admin
   Allowed member types: Users/Groups + Applications
   Value: Admin
   Description: Admin
   Do you want to enable this app role?: Yes
   Apply
```

1.3 Configurar API Permissions
```cmd
Acessar API Permissions
Add a permission
Microsoft Graph
Delegated permissions
User.Read
Add permissions
```

1.4 Configurar Authentication
```cmd
Acessar Authentication
Enable implicit grant and hybrid flows:
   Access tokens: Yes
   ID tokens: Yes
Save
```

1.5 Configurar Certificates & secrets
```cmd
Acessar Certificates & secrets
New client secret
   Description: secret
   Expires: 18 months
   Add
IMPORTANTE: Copiar o valor do secret gerado
```

1.6 Configurar Pre-authorized applications
```cmd
Acessar Expose an API
Add a client application
   Client ID: (copie o seu ID)
   Authorized scopes: AdminApi
   Add application
```

1.7 Configurar Service Principal Lock
```cmd
Acessar Branding & properties
Service Principal Lock:
   Enable service principal lock: Yes
   Lock:
      - All Properties
      - Credentials with usage verify
      - Credentials with usage sign
      - Token encryption key ID
Save
```
2.0 Criar o App Registration CRM.APP.SITE
```cmd
Acessar o Azure Portal
Acessar Microsoft Entra ID
App Registrations - New Registration
Nome: CRM.APP.SITE
Suported account types: Single tenant
Platform configuration: Web
   Redirect URI: https://sua-url-app-service/signin-oidc
Register
```

2.1 Configurar Expose an API
```cmd
Acessar o App Registration criado
Selecionar Expose an API
Set Application ID URI: api://(copie o seu ID)
Add a scope:
   - Scope name: scope_crm
   - Who can consent?: Admins only
   - Admin consent display name: scope_crm
   - Admin consent description: scope_crm
   - State: Enabled
   - Add scope
```

2.2 Configurar App Roles
```cmd
Acessar App roles
New app role:
   Display name: AdminOnly
   Allowed member types: Users/Groups + Applications
   Value: Admin
   Description: Admin
   Do you want to enable this app role?: Yes
   Apply
```

2.3 Configurar API Permissions
```cmd
Acessar API Permissions
Add a permission
Microsoft Graph:
   - openid (Delegated)
   - profile (Delegated)
   - offline_access (Delegated)
   - User.Read (Delegated)

CRM.API:
   - AdminApi (Delegated)
Add permissions
```

2.4 Configurar Authentication
```cmd
Acessar Authentication
Platform configurations: Web
Redirect URIs: https://sua-url-app-service/signin-oidc
Enable implicit grant and hybrid flows:
   Access tokens: Yes
   ID tokens: Yes
Save
```

2.5 Configurar Certificates & secrets
```cmd
Acessar Certificates & secrets
New client secret
   Description: secret
   Expires: 18 months
   Add
IMPORTANTE: Copiar o valor do secret gerado
```

2.6 Configurar Service Principal Lock
```cmd
Acessar Branding & properties
Service Principal Lock:
   Enable service principal lock: Yes
   Lock:
      - All Properties
      - Credentials with usage verify
      - Credentials with usage sign
      - Token encryption key ID
Save
```

2.7 Configurar Token configuration
```cmd
Acessar Token configuration
Add optional claims:
   Token type: Access
   Save
```

## STEP07 - Configurar as variáveis de ambiente crm
1.0 Configurar as variáveis de ambiente da aplicação CRM
```cmd
[
  {
    "name": "ApiSettings:BaseUrl",
    "value": "https://sua-url-bend-app-service.azurewebsites.net/",
    "slotSetting": true
  },
  {
    "name": "AuthSettings:BaseUrl",
    "value": "https://sua-url-auth-app-service.azurewebsites.net/",
    "slotSetting": false
  },
  {
    "name": "AuthSettings:Scopes",
    "value": "api://scope-id/AdminApi",
    "slotSetting": false
  },
  {
    "name": "AzureAD:Audience",
    "value": "api://clientid",
    "slotSetting": true
  },
  {
    "name": "AzureAD:Authority",
    "value": "https://login.microsoftonline.com/tenantid",
    "slotSetting": true
  },
  {
    "name": "AzureAD:CallbackPath",
    "value": "/signin-oidc",
    "slotSetting": true
  },
  {
    "name": "AzureAD:ClientId",
    "value": "clientid",
    "slotSetting": true
  },
  {
    "name": "AzureAD:ClientSecret",
    "value": "client-secret",
    "slotSetting": true
  },
  {
    "name": "AzureAD:Issuer",
    "value": "https://sts.windows.net/tenantid",
    "slotSetting": true
  },
  {
    "name": "AzureAD:TenantId",
    "value": "tenantid",
    "slotSetting": true
  },
  {
    "name": "WEBSITE_ENABLE_SYNC_UPDATE_SITE",
    "value": "true",
    "slotSetting": false
  },
  {
    "name": "WEBSITE_RUN_FROM_PACKAGE",
    "value": "1",
    "slotSetting": false
  }
]
```

1.1 Testar o acesso CRM autenticando com o Entra ID
```cmd
Acessar o endereço do webapp de CRM
Na tela de login do Entra ID, autenticar com um usuário com permissão
```

## STEP08 - Deploy do Tenant do Azure B2C
1.0 Criar um novo Azure Active Directory B2C
```cmd
Cllicar em "Create a resource"
Digitar a opção "Azure Active Directory B2C"
Escolher "Create a new Azure AD B2C Tenant"
Digitar um nome para a organização
Digitar um domain name para a organização
Escolher o Resource Group: rg-tftecsp
```

## STEP09 - Deploy Apps Registration demais aplicações 

1.0 Criar o App Registration SISTEMA.API.LOJA
```cmd
Acessar o Azure Portal
Acessar Azure AD B2C
App Registrations - New Registration
Nome: SISTEMA.API.LOJA
Suported account types: Accounts in any identity provider or organizational directory
Register
```

1.1 Configurar Expose an API
```cmd
Acessar o App Registration criado
Selecionar Expose an API
Set Application ID URI: https://tftecsp.onmicrosoft.com/(copie o seu ID)
Add a scope:
   - Scope name: ClientAPI
   - Who can consent?: Admins only
   - Admin consent display name: ClientAPI
   - Admin consent description: ClientAPI
   - State: Enabled
   - Add scope
```

1.2 Configurar API Permissions
```cmd
Acessar API Permissions
Add a permission
Microsoft Graph:
   - profile (Delegated)
   - email (Delegated)
Add permissions
```

1.3 Configurar Token Version
```cmd
Acessar Manifest
Localizar "accessTokenAcceptedVersion": null
Alterar para "accessTokenAcceptedVersion": 2
Save
```

1.4 Configurar Authentication
```cmd
Acessar Authentication
Platform configurations: None
Enable implicit grant and hybrid flows:
   Access tokens: No
   ID tokens: No
Save
```

1.5 Configurar Application ID URI
```cmd
Acessar Expose an API
Application ID URI: https://tenant-b2c.onmicrosoft.com/(copie o seu ID)
Save
```

1.6 Configurar Publisher Domain
```cmd
Publisher Domain será automaticamente configurado como: tenant-b2c.onmicrosoft.com
```

2.0 Criar o App Registration SISTEMA.LOJA
```cmd
Acessar o Azure Portal
Acessar Azure AD B2C
App Registrations - New Registration
Nome: SISTEMA.LOJA
Suported account types: Accounts in any identity provider or organizational directory
Platform configuration: Web
   Redirect URI: https://ingresso.tftecspdev.shop/signin-oidc
Register
```

2.1 Configurar API Permissions
```cmd
Acessar API Permissions
Add a permission
Microsoft Graph:
   - profile (Delegated)
   - email (Delegated)

SISTEMA.API.LOJA:
   - ClientAPI (Delegated)
Add permissions
```

2.2 Configurar Token Version
```cmd
Acessar Manifest
Localizar "accessTokenAcceptedVersion": null
Alterar para "accessTokenAcceptedVersion": 2
Save
```

2.3 Configurar Authentication
```cmd
Acessar Authentication
Platform configurations: Web
Redirect URIs: https://ingresso.tftecspdev.shop/signin-oidc
Enable implicit grant and hybrid flows:
   Access tokens: Yes
   ID tokens: Yes
Save
```

2.4 Configurar Certificates & secrets
```cmd
Acessar Certificates & secrets
New client secret
   Description: secret
   Expires: 18 months
   Add
IMPORTANTE: Copiar o valor do secret gerado
```

2.5 Configurar Publisher Domain
```cmd
Publisher Domain será automaticamente configurado como: tftecsp.onmicrosoft.com
```

## STEP9.1 - Configurar as variáveis de ambiente demais ambientes

1.0 Configurar as variáveis de ambiente da aplicação INGRESSO
```cmd
[
  {
    "name": "ApiSettings:BaseUrl",
    "value": "https://seu-app-service-bend.azurewebsites.net/",
    "slotSetting": true
  },
  {
    "name": "AuthSettings:BaseUrl",
    "value": "https://seu-app-service-auth.azurewebsites.net/",
    "slotSetting": false
  },
  {
    "name": "AzureAdB2C:CallbackPath",
    "value": "/signin-oidc",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:ClientId",
    "value": "9e9cac22-2af0-4e5a-857f-65a8f0d75a49",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:ClientSecret",
    "value": "secret",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:Domain",
    "value": "tftecsp.onmicrosoft.com",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:EditProfilePolicyId",
    "value": "B2C_1_Edit",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:Instance",
    "value": "https://seu-tenant.b2clogin.com/",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:ResetPasswordPolicyId",
    "value": "B2C_1_reset",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:SignUpSignInPolicyId",
    "value": "B2C_1_login",
    "slotSetting": true
  },
  {
    "name": "AzureAdB2C:TenantId",
    "value": "81fc41c5-94cd-4ac4-a73d-b47ae10e39f3",
    "slotSetting": true
  },
  {
    "name": "WEBSITE_ENABLE_SYNC_UPDATE_SITE",
    "value": "true",
    "slotSetting": false
  }
]
```
1.1 Configurar as variáveis de ambiente da aplicação BEND
```cmd
[
  {
    "name": "AzureAD:Audience",
    "value": "clientid",
    "slotSetting": false
  },
  {
    "name": "AzureAD:ClientId",
    "value": "clientid",
    "slotSetting": false
  },
  {
    "name": "AzureAD:Domain",
    "value": "partiunuvem.com",
    "slotSetting": false
  },
  {
    "name": "AzureAD:Instance",
    "value": "https://login.microsoftonline.com/",
    "slotSetting": false
  },
  {
    "name": "AzureAD:TenantId",
    "value": "tenantid",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:Issuer",
    "value": "tenantid",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:Authority",
    "value": "tenantid",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:Audience",
    "value": "audience",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:ClientId",
    "value": "clientid",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:CallbackPath",
    "value": "/signin-oidc",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:SignUpSignInPolicyId",
    "value": "B2C_1_login",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:ResetPasswordPolicyId",
    "value": "B2C_1_reset",
    "slotSetting": false
  },
  {
    "name": "AzureB2C:EditProfilePolicyId",
    "value": "B2C_1_Edit",
    "slotSetting": false
  },
  {
    "name": "AzureBlobStorage:ConnectionString",
    "value": "access-key",
    "slotSetting": false
  },
  {
    "name": "AzureBlobStorage:content_url",
    "value": "https://seu-sto.blob.core.windows.net/container-images",
    "slotSetting": false
  },
  {
    "name": "AzureBlobStorage:RepositorioBlob",
    "value": "container-images",
    "slotSetting": false
  },
  {
    "name": "WEBSITE_ENABLE_SYNC_UPDATE_SITE",
    "value": "true",
    "slotSetting": false
  },
  {
    "name": "WEBSITE_NODE_DEFAULT_VERSION",
    "value": "6.9.1",
    "slotSetting": false
  },
  {
    "name": "WEBSITE_RUN_FROM_PACKAGE",
    "value": "1",
    "slotSetting": false
  }
]
```
1.2 Configurar as variáveis de ambiente da aplicação AUTH
```cmd
  {
    "name": "AzureAD:Audience",
    "value": "api://d72a4f3c-74f9-46f5-a1d0-6a159f89855c",
    "slotSetting": true
  },
  {
    "name": "AzureAD:Authority",
    "value": "https://login.microsoftonline.com/cab1ba99-21e0-4a40-8f98-aef71b9b0f80",
    "slotSetting": true
  },
  {
    "name": "AzureAD:CallbackPath",
    "value": "/signin-oidc",
    "slotSetting": true
  },
  {
    "name": "AzureAD:ClientId",
    "value": "d72a4f3c-74f9-46f5-a1d0-6a159f89855c",
    "slotSetting": true
  },
  {
    "name": "AzureAD:ClientSecret",
    "value": "secret",
    "slotSetting": true
  },
  {
    "name": "AzureAD:Issuer",
    "value": "https://sts.windows.net/cab1ba99-21e0-4a40-8f98-aef71b9b0f80",
    "slotSetting": true
  },
  {
    "name": "AzureAD:TenantId",
    "value": "cab1ba99-21e0-4a40-8f98-aef71b9b0f80",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:Audience",
    "value": "713c03e8-2067-4fe5-86f1-885a730d6a90",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:Authority",
    "value": "https://tftecsp.b2clogin.com/8277e546-2d6f-4233-81f3-d3760ad7a0d2/v2.0/",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:CallbackPath",
    "value": "/signin-oidc",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:ClientId",
    "value": "9e9cac22-2af0-4e5a-857f-65a8f0d75a49",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:ClientSecret",
    "value": "secret",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:EditProfilePolicyId",
    "value": "B2C_1_Edit",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:Issuer",
    "value": "https://seu-tenant.b2clogin.com/8277e546-2d6f-4233-81f3-d3760ad7a0d2/v2.0/",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:KeysEndpoint",
    "value": "https://seu-tenant.b2clogin.com/tftecsp.onmicrosoft.com/discovery/v2.0/keys?p=b2c_1_login",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:ResetPasswordPolicyId",
    "value": "B2C_1_reset",
    "slotSetting": true
  },
  {
    "name": "AzureB2C:SignUpSignInPolicyId",
    "value": "B2C_1_login",
    "slotSetting": true
  }
]
```

## STEP10 - Realizar teste completo para todas as aplicações
1.0 Testar experiência no ambiente de Compra e CRM
```cmd
BEND: Realizar um teste de GET nos dados de costumer
INGRESSO: Realizar o cadastro de um usuário no site utilizando AZURE B2C e realizar uma compra de produto.
CRM: Realizar a autenticação utilizando um usuário com permissão no Entra ID e validar a compra realizada no passo anterior.
```

## STEP11 - Realizar ajustes de conectividade no SQL Database e WebApps
1.0 Configurar o SQL Database para trabalhar com private endpoint
```cmd
Acessar o menu Networking
Public network access: Disable
Private Access - Criar um private endpoint
Name: pvt-endp-sql-001
Network Interface Name: pvt-endp-sql-001-nic
Region: uksouth
Target sub-resource: sqlServer
Virtual network: vnet-spk-001
Subnet: sub-db-001
Dynamically allocate IP address
```
1.1 Configurar VNET Integration para o WebApps INGRESSO
```cmd
Acessar o menu Networking
Clicar em Virtual network integration - Not configured
Add Virtual Network Integration
Virtual Network: vnet-spk-001
Subnet: sub-vint-001
```

1.2 Configurar VNET Integration para o WebApps CRM
```cmd
Acessar o menu Networking
Clicar em Virtual network integration - Not configured
Add Virtual Network Integration
Selecionar a connection já criada no passo anterior
```

1.3 Configurar VNET Integration para o WebApps BEND
```cmd
Acessar o menu Networking
Clicar em Virtual network integration - Not configured
Add Virtual Network Integration
Selecionar a connection já criada no passo anterior
```

1.4 Configurar VNET Integration para o WebApps AUTH
```cmd
Acessar o menu Networking
Clicar em Virtual network integration - Not configured
Add Virtual Network Integration
Selecionar a connection já criada no passo anterior
```

1.5 Realizar testes de acesso
```cmd
Teste via BEND - Swagger
Teste de login no CRM via Entra ID
Teste de login B2C no Ingresso
```


## STEP12 - Deploy certificados Digitais
1.0 Gerar um certificado digital válido:
https://punchsalad.com/ssl-certificate-generator/
```cmd
Criar um certificado digital para a URL que será utilizada em cada uma das aplicações (usando como sufixo o seu domínio público.)
```

1.1 Converter o certificado para PFX:
https://www.sslshopper.com/ssl-converter.html
```cmd
Gerar o certificado cno formato pfx
Cadastrar uma senha simples para o certificado. Exemplo: tftec2024
```

1.2 repetir o passo de criação 4 vezes:
```cmd
 - Certificado para aplicação INGRESSO
 - Certificado para aplicação BEND (api)
 - Certificado para aplicação AUTH (api)
 - Certificado para aplicação CRM
```

## STEP13 - Deploy Azure Key Vault
1.0 Deploy Azure Key Vault:
```cmd
   Nome: kvault-tftec-001
   Região: uksouth
   Configurar o acesso ao Key Vault como Access Policy
```

1.1 Fazer upload dos certificado PFX no Key Vault
```cmd
Fazer upload do certificado pfx da aplicação INGRESSO
Fazer upload do certificado pfx da aplicação CRM
Fazer upload do certificado pfx da aplicação BEND (API)
Fazer upload do certificado pfx da aplicação AUTH (API)
```

## STEP14 - Criar um Managed Identity
1.0 Criar um Managed Identity para liberar acesso do AppGw aos certificados do KeyVault
```cmd
Resource Group: rg-tftecsp-001
Region: uksouth
Name: mgtid-kvault-certs
```
1.2 Liberando acesso do Managed Identity no Key Vault
```cmd
Acessar o Key Vault crido no STEP12
Adicionar uma Access policies
Secret e Certification permitions: GET
```

## STEP15 - Deploy AKS
1.0 Acessar a seguinte estrutura: https://github.com/raphasi/tftecsp2024/tree/main/01-Azure-DevOps-Terraform


FIM DO PRIMEIRO DIA!!





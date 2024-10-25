# Imersão TFTEC Azure ao vivo em SP

Esse projeto descreve os principais passos utilizados no nosso treinamento presencial de SP.
Temos como objetivo construir uma infraestrutura completa, simulando um cenário real de uma empresa que tem a necessidade de utilizar diversos recursos do Azure para rodar o seu negócio.

# Estrutura
O desenho de arquitetura informado abaixo mostra alguns detalhes de como está configurada a estrutura da empresa que iremos construir.

![TFTEC Cloud](https://github.com/raphasi/imersaoazure/blob/main/Arquitetura.png "Arquitetura Imersão")

## STEP01 - Criar um Resource Group e aplicar Azure Policy
1- Criar Resource Group
```cmd
   # Criar um Resource Group
   Nome: rg-azure
   Região: East US
 ```
2- Aplicar Azure Policy
   - Aplicar Policy no nível do Resource Group criado no passo anterior
   - Aplicar policy para recursos herdarem a TAG do RG-AZURE (Inherit a tag from the resource group)
   - Aplicar policy para limitar o tamanho das VMs para B2S e D2S_V3 (Allowed virtual machine size SKUs)
         - Configurar mensagem de não complice: Você escolheu um SKU de VM não permitido, Utilize apenas B2S ou D2S_V3
   


## STEP02 - Criar a topologia de rede HUB-SPOKE
Iremos utilizar pelo menos, 5 regiões diferentes do Azure, com o objetivo de atendermos as restrições de vCpus existentes em contas trial do Azure.

1 - Criar a estrutura da VNET-HUB:

```cmd
   # Criar um Resource Group
   Nome: rg-azure
   Região: East US
   
   # VNET-HUB
   Nome: vnet-hub
   Região: East-US
   Adress Space: 10.10.0.0/16
      
   # Subnets   
   Subnet: sub-srv
   Address Space: 10.10.1.0/24
   
   Subnet: sub-db
   Address Space: 10.10.2.0/24
   
   Subnet: sub-pvtendp
   Address Space: 10.10.252.0/24
   
   Subnet: AzureBastionSubnet
   Address Space: 10.10.250.0/24
   
   Subnet: GatewaySubnet
   Address Space: 10.10.251.0/24
   
```

2 - Criar a estrutura da VNET-SPOKE01:

```cmd
   # VNET-SPOKE01
   Nome: vnet-spoke01
   Região: UK South
   Adress Space: 10.20.0.0/16
   
   # Subnets
   Subnet: sub-intra
   Address Space: 10.20.1.0/24
     
```

3 - Criar a estrutura da VNET-SPOKE02:

```cmd
   # VNET-SPOKE02
   Nome: vnet-spoke02
   Região: Japan East
   Adress Space: 10.30.0.0/16
   
   # Subnets
   Subnet: sub-web
   Address Space: 10.30.1.0/24
   
   Subnet: sub-appgw
   Address Space: 10.30.250.0/24
     
```

## STEP03 - Deploy dos NSGs
Criar 3 NSGs de acordo com o modelo abaixo:
```cmd
   Nome: nsg-hub
   Região: east-us
   Associar Subnet: sub-srv e sub-db
```

```cmd
   Nome: nsg-intra
   Região: uk-south
   Associar Subnet: sub-intra
```

```cmd
   Nome: nsg-web
   Região: japan-east
   Associar Subnet: sub-web
```

## STEP04 - Deploy das VMs
Para todas as VMs iremos o tamanho B2S e utilizar o sistema operacional Windows Server 2022.

```cmd
   # EAST US
   Nome: vm-apps
   Região: east-us
   Vnet: vnet-hub
   Subnet: sub-srv
```

```cmd
OBS: Na conta trial pode não existir a disponibilidade de usar duas Zonas, caso isso aconteça, não utilize nenhuma configuração de alta disponibilidade.
   # UK SOUTH
   Nome: vm-intra01
   Região: uk-south
   Zone: Zone 1
   Vnet: vnet-spoke01
   Subnet: sub-intra
   
   Nome: vm-intra02
   Região: uk-south
   Zone: Zone 2
   Vnet: vnet-spoke01
   Subnet: sub-intra
```

```cmd 
   # JAPAN EAST
   Nome: vm-web01
   Região: japan-east
   Zone: Zone 1
   Vnet: vnet-spoke02
   Subnet: sub-web
   
   Nome: vm-web02
   Região: japan-east
   Zone: Zone 2
   Vnet: vnet-spoke02
   Subnet: sub-web
 ```  
 
   
2 - Deploy Azure Bastion

```cmd
   Nome: bastion01
   Região: East US
   SKU: Standard
   Configuration: Shareable
```

3 - Desabilitar o firewall de todas as VMs via Run Command, usando o seguinte comando:

```cmd
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
```

4 - Acessar as VMs via Bastion e realizar teste de ping entre VMs de vnets diferentes.

5 - Criar peering entre as seguintes vnets:
```cmd
vnet-hub/vnet-spoke01 - vnet-spoke01/vnet-hub
vnet-hub/vnet-spoke02 - vnet-spoke02/vnet-hub
```
4 - Realizar teste de ping entre VMs de vnets diferentes novamente.

## STEP05 - Configuração de domínios e certificados
1 - Criar um DNS Zone (Zona de DNS pública no Azure).

2 - Apontar registros NS (name server) do provedor público para o Azure.
Testar a validação do DNS com o seguinte comando:
```cmd
nslookup -type=SOA tftecprime.cloud
```
3 - Gerar um certificado digital válido:

Opções:

OPÇÃO01: https://app.zerossl.com

OPÇÃO02: https://punchsalad.com/ssl-certificate-generator/

4 - Converter o certificado para PFX:

https://www.sslshopper.com/ssl-converter.html


## STEP06 - Deploy Azure Key Vault
1- Deploy Azure Key Vault:
```cmd
   Nome: kvault-certs
   Região: east-us
   Private Endpoint: pvt-kvault
   Usar pvt enpdoint na vnet-hub e subnet sub-pvtendp 
```

2- Fazer upload do certificado PFX no Key Vault
```cmd
   Como o acesso externo está desabilitado, upload do certificado precisa ser feito de uma VM do Azure.
   Acessar a VM-APPS e fazer o upload do certificado.
   ```
3- Criar um managed identify e conceder permissão no Key Vault como:
```cmd
   Nome: svcappgwcert
   Secret: Get
```

5- Associar VNET-SPOKE02 a Zona de DNS do Private Endpoint
   - Acessar a zona de dns criada pelo private endpoint: privatelink.database.windows.net 
   - Associar a vnet-spoke02

## STEP07 - Deploy estrutura INTRANET
1- Instalar IIS nas VMS vm-intra01 e vm-intra02:
```cmd
Install-WindowsFeature -name Web-Server -IncludeManagementTools
```

2- Baixar código da aplicação aplicação do seguinte link do Github:

https://github.com/raphasi/imersaoazure/archive/refs/heads/main.zip

3- Copiar pasta da aplicação para o seguinte caminho
```cmd
c:\inetpub\wwwroot
```

4- Criar um novo site no IIS
```cmd
Stop no Default Web Site
Nome: Intranet
Porta: 80
```
5- Executar somente na VM-INTRA02
```cmd
Acessar a pasta C:\inetpub\wwwroot\Intranet\Index.html
Alterar o arquivo index.html na linha 113
Alterar nome da vm para VM-INTRA02
```

## STEP08 - Deploy Azure Load Balancer
1- Deploy Load Balancer 
```cmd
   Nome: lb-intra
   Tipo: Interno
   Região: uk-south
   Sku: Standard 
   Frontend IP: Static - 10.20.1.100
   Backend: bepool-intra
   Load Balance Rule: rule-intra80
   Probe: probe-80
```
## STEP09 - Deploy Nat Gateway
1- Deploy Nat Gateway
```cmd
   Nome: nat-gw01
   Região: uk-south
   Public IP Address: pip-internet01
   
```
2- Associar a subnet sub-intra
```cmd
   Selecionar VNET: vnet-spoke01
   Marcar a subnet: sub-intra

```



## STEP10 - Deploy Aplicação Web Site
1- Instalar IIS nas VMS vm-web01 e vm-web02
```cmd
Install-WindowsFeature -name Web-Server -IncludeManagementTools
```
2- Instalar .net core:

https://dotnet.microsoft.com/en-us/download/dotnet/thank-you/runtime-aspnetcore-7.0.5-windows-hosting-bundle-installer

3- Baixar código da aplicação aplicação do seguinte link do Github:

https://github.com/raphasi/imersaoazure.git

4- Copiar pasta da aplicação para o seguinte caminho
```cmd
c:\inetpub\wwwroot
```
5- Criar um novo site no IIS
```cmd
Nome: WebSite
Porta: 80
```

## STEP11 - Deploy SQL Server
1- Criar um novo SQL Server
```cmd
Nome: sqlsrvtftec01 (usar um nome único)
Location: east-us
Authentication method: Use SQL authentication   
   user: adminsql
   pass: Partiunuvem@2023
Allow Azure services and resources to access this server: YES

```

## STEP12 - Deploy SQL Database
1- Deploy SQL Database
```cmd
Nome: xxxxxxx
Server: Usar o server criado no passo anterior
Compute + storage: Usar o Service Tier - DTU BASED - BASIC 
Backup storage redundancy: LRS
Add current client IP address: YES
Add Private Endpoint: pvt-sqldb01
Usar pvt enpdoint na vnet-hub e subnet sub-pvtendp
```


## STEP13 - Importar Database 
1- Instalar o SSMS
```cmd
Acessar o servidor vm-apps e instalar o SQL Management Studio
```
https://aka.ms/ssmsfullsetup

2- Importar database aplicação WebSite
```cmd
Abrir o SQL Management Studio
Server Name: Copia o nome do SQL Server criado no passo anterior
Alterar formato de autenticação para SQL Server authentication  
Logar com usuário e senha criados no passo anterior
Importar o database usando a opção de dacpac
*Caso necessário, alterar o nome do database para: sistemabadge_database
```

3- Ajustar SQL Database
```cmd
Ajustar configuração do SQL Database:
   - Compute + Storage: Mudar opção de backup para LRS
```

4- Ajustar configuração de rede para SQL Server
Acessar o SQL Server criado e ajustar configuração de Networking:
   - Add Private Endpoint: pvt-sqldb01
   - Usar pvt enpdoint na vnet-hub e subnet sub-pvtendp
   - Public network acess: Disable

5- Associar VNET-SPOKE02 a Zona de DNS do Private Endpoint
   - Acessar a zona de dns criada pelo private endpoint: privatelink.database.windows.net 
   - Associar a vnet-spoke02
   
   
6- Alterar connection string dos servidores
```cmd
Acessar as VMs vm-web01 e vm-web02
Acessar o arquivo C:\inetpub\wwwroot\WebSite\appsetting.json 
Alterar a connection string o nome do banco de acordo com o banco criado
Abrir o promt de comando como administrador e realizar executar o comando iisreset nas duas vms
Testar abrir a aplicação usando localhost
```


## STEP14 - Application Gateway
**EXECUTAR ESSES PASSO EM UMA VM DO AZURE**
1- Deplou Apg Gateway
```cmd
   Nome: appgw-site
   Região: japan-east
   Tier: Standard 2
   Tipo: Public IP Address
   Frontend: Public
   Public IP Adress: pip-appgw-site
   Backend: bepool-web
```

```cmd
   Configurar primeiramente acesso a porta 80
   Rule01: rule-http-web
   Priority: 100
   Listener: lst-80
   Protocol: HTTP
   Backend Setting: bset80
``` 

2- Criar um ASG
```cmd
   Nome: asg-web
   Região: japan-east   
```

3- Associar a placa de rede das seguintes VMs ao ASG:
```cmd
  vm-web01
  vm-web02
```

4- Liberar regra no NSG nsg-web
```cmd
Criar regra, liberando qualquer origem, setar o destino com o Application Security Group e usar portas 80 e 443.
```

5- Ajustar acesso para forçar porta HTTPS (443)
```cmd   
   Configurar acesso via porta 443
   Rule01: rule-https-web
   Priority: 101
   Listener: lst-443
   Protocol: HTTPS 
   Choose a certificate:  Choose a certificate from Key Vault
   Backend Setting: bset80
 ```  
 
 ```cmd 
 Redirecionar acesso da porta 80 para 443 (https)
   Rule01: rule-http-web
   Listener: lst-80
   Protocol: HTTP
   Backend Setting: bset80
   Target type: Redirection
   Redirection Type: Permanent
   Redirection Target: Listener - lst-443
```

6- Ajustar registro DNS externo
```cmd
Acessar a zona de DNS público e criar um registro do A.
Usar Alias Record Set e apontar para o IP público do App Gateway.
```

## STEP15 - Deploy Storage Account Público
1- Deploy Storage Account
```cmd
   Nome: tftecimages01 (usar seu nome exclusivo)
   Região: east-us
   Performance: Standard
   Redundancy: GRS - Marcar opção para  Read Access
   Storage Sub-Resource: Blob
```
2- Criar um Container blob
```cmd
   Nome: blob-tftec-container (container precisa ter esse nome exato)
```


## STEP16 - Deploy Storage Account Privado
1- Deploy Storage Account
```cmd
   Nome: tftecfiles01 (usar seu nome exclusivo)
   Região: east-us
   Performance: Standard
   Redundancy: GRS - Marcar opção para  Read Access
   Usar pvt enpdoint na vnet-hub e subnet sub-pvtendp
   Private Enpoint Name: pvt-files01
   Storage Sub-Resource: Files
```
2- Associar VNET-SPOKE01 Zona de DNs do Private Endpoint do Files
```cmd
   Associar vnet-intra na zona de dns privatelink.file.core.windows.net
```
3- Criar um Azure Files
```cmd
   Nome: corp
```
4- Mapear Azure Files
```cmd
OBS: NÃO abrir o PowerShell como Admninistrator
   Mapear o Azure Files nas seguintes VMs:
   vm-intra01
   vm-intra02
```
Validar se a conexão está apontando para ip interno


## STEP17 - Deploy Aplicação Imagens (WebApp)
1- Criar um App Service Plan
```cmd
   Nome: appplantftec
   Operating System: Windows
   Região: east-us
   Pricing plan: Standard S2 (caso a conta trial não mostre o modelo S2, escolha o S1 e depois faça upgrade para o S2)
   ```
2- Criar um WebApp
```cmd
   Nome: tftecimages01 (usar seu nome exclusivo)
   Publish: Code
   Runtime Stack: ASP.NET V4.8
   Região: east-us
   Escolher AppServicePlan já criado
```
3- Deploy da aplicação
Baixar o zip da aplicação em 
https://github.com/raphasi/imersaoazure


4- Ajustar application setting para endereço do Storage Account
   - Ajustar o arquivo web.config, com a string do Storage Account
  ```cmd
   Para montar o conteúdo do VALUE você deve pegar o valor da connection string do Access Key do Storage Account e juntar com os endereços de endpoint dos serviços, como o exemplo:
   Value: DefaultEndpointsProtocol=https;AccountName=tftecimages0000001;AccountKey=3QPIgPlxUYhzKLu43wsC19EGnvpqKMDNiGIRYxXDHm+zm3w/x/g0fnb+AStUGrxZA==;BlobEndpoint=https://tftecimages000001.blob.core.windows.net/;TableEndpoint=https://tftecimages000001.table.core.windows.net/;QueueEndpoint=https://tftecimages000001.queue.core.windows.net/;FileEndpoint=https://tftecimages000001.file.core.windows.net/
   
   Zipar o conteúdo novamente.
   ```
   
 5- Realizar o deploy da aplicação para o WebApp
Abrir o CloudShell e fazer upload do arquivo DeployBlob.zip
```cmd
az webapp deploy --resource-group rg-azure --name <app-name> --src-path DeployBlob.zip
```
   

## STEP17 - Deploy VPN Site to Site (S2S)
1- Criar a estrutura da VNET-ONPREMISES

```cmd
   # Criar um Resource Group
   Nome: rg-onpremises
   Região: Brazil South
   
   # VNET-ONPREMISES
   Nome: vnet-onpremises
   Região: Brazil-South
   Adress Space: 192.168.0.0/16
      
   # Subnets   
   Subnet: sub-onpremises
   Address Space: 192.168.1.0/24
```

2- Deploy Virtual Network Gateway
```cmd
   Nome: vng01
   Região: brazil-south
   Gateway type: VPN
   SKU: VpnGw1
   Virtual Network: vnet-onpremises
   Public IP address name: pip-vng01
   Enable active-active mode: Disabled
   
OBS: Deploy pode levar mais de 30 minutos
```
3- Deploy VM Firewall
  ```cmd
   Nome: vm-fw
   Região: brazil-south
   Vnet: vnet-onpremises
   Subnet: sub-onpremises
   Usar um IP público stático
   Habilitar o forwarding da placa de rede
   ```
4- Instalar a feature de RAS na VM-FW
   - Criar uma interface: Azure utilizando o IP público do Virtual Network Gateway
   - Criar rota estática para rede 10.10.0.0/16
   - Criar rota estática para rede 10.20.0.0/16
   - Criar rota estática para rede 10.30.0.0/16
   - Configurar conexão persistente
   - Configurar uma chave compartilhada para conexão VPN

5- Criar um Local Network Gateway
   ```cmd
   Nome: lng01
   Região: brazil-south
   Endpoint: IP Address
   IP address: IP Público da vm-fw
   Address Space(s): 192.168.0.0/16
   ```
   
6- Criar um Connection
```cmd
   Nome: VPNAzure-Onpremises
   Connection Type: Site-to-Site
   Shared key (PSK): mesmo criado na configurção do RAS
   ```
 7- Deploy VM Client
  ```cmd
   Nome: vm-clieny
   Região: brazil-south
   Sistema Operacional: Windows 11
   Vnet: vnet-onpremises
   Subnet: sub-onpremises
   ```

## STEP18 - Realizar ajustes do perring na VNETs 
1- Ajustar Peering entre HUB e os Spokes (HUB)
```cmd
Virtual network gateway or Route Server
Use this virtual network's gateway or Route Server
```
2- Ajustar Peering entre HUB e os Spokes (Spoke01 e Spoke02)
```cmd
Virtual network gateway or Route Server
Use the remote virtual network's gateway or Route Server
```

## STEP19 - Deploy Route Table
1- Criar Route Table
```cmd
Nome: rtable-onpremises
Região: brazil-south
```
2- Criar rotas
```cmd
# ROTA REDE HUB
Nome: route-hub
Addres: 10.10.0.0/16
Next Hope: Virtual Appliance

# ROTA REDE SPOKE01
Nome: route-spoke01
Addres: 10.20.0.0/16
Next Hope: Virtual Appliance

# ROTA REDE SPOKE02
Nome: route-spoke02
Addres: 10.30.0.0/16
Next Hope: Virtual Appliance
```
3- Associar Route Table a subnet
```cmd
Associar o Route Table a subnet sub-onpremises
```

## STEP20 - Deploy VPN Point to Site
1- Configuração do VPN P2S
- Address pool: 172.16.0.0/24
   - Tunnel type: OpenSSL
   - Authentication type: Azure Active Directory
     Dados do Azure Active Directory
```cmd
Tenant ID: https://login.microsoftonline.com/"your Directory ID"
Audience: 41b23e61-6c1e-4545-b367-cd054e0ed4b4 
Issuer: https://sts.windows.net/"your Directory ID"/
```  
2- Ajusra resolução de nomes para VPN
   - Instalar a role de IIs na VM-APPS
   - Criar uma regra de forward do endereço do seu dns interno para o IP de DNS do Azure (168.63.129.16)

3- Ajustar o cliente de VPN
   - Adicionar a TAG com o endereço de VPN ao arquivo azurevpnconfig.xml
   ```cmd
 <clientconfig>
	<dnsservers>
		<dnsserver>10.10.1.4</dnsserver>
	</dnsservers>
</clientconfig>
   ```  


## STEP21 - Deploy APIM - API Management service
  ```cmd
   Cluster present configuration: Standard
   Nome: apim-tftec01
   Região: east-us
   Organization Name: TFTEC Cloud
   Administrator email: seu email para notificações
   Pricing tier: Developer
   ```
   
## STEP22 - Import Azure SQL Database
```cmd
Abrir o SQL Management Studio
Server Name: Copiar o nome do SQL Server já existente
Alterar formato de autenticação para SQL Server authentication  
Logar com usuário e senha usados na criação do banco
Importar o database usando a opção de dacpac
Manter o nome do database como apim_database
```

## STEP23 - Deploy WebApp API
1- Criar um WebApp
```cmd
   Nome: tftecapi01 (usar seu nome exclusivo)
   Publish: Code
   Runtime Stack: .NET6
   Região: east-us
   Escolher AppServicePlan já criado
```
2- Deploy da aplicação
Baixar o zip da aplicação em 
https://github.com/raphasi/imersaoazure

3- Realizar o deploy da aplicação para o WebApp
Abrir o Powershell ou Terminal e executar o seguinte comando:
```cmd
az login (ou utilizar o CloudShell)
az webapp deploy --resource-group rg-azure --name <app-name> --src-path DeploymentAPI.zip
```
4- Ajustar application setting para endereço do SQL Database
   - Acessar o WebApp - Configuration
   - Connection string
   - New connection string
   - Add/Edit connection string
  ```cmd
   Name: DefaultConnection
   Value: Server=tcp:sqlsrvtftec00001.database.windows.net,1433;Initial Catalog=apim_database;Persist Security Info=False;User ID=adminsql;Password=Partiunuvem@2023;MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;
   Type: SQLAzure
   SAVE
   ``` 
   
5- Ajustar conexão interna do WebApp com o Azure SQL Database
   - Acessar o WebApp criado no passo anterior
   - Networking
   - Outbound Traffic
   - Vnet Integration
   - Add VNet
   - Escolher a vnet-hub
   - Escolher a subnet sub-db


## STEP24 - Deploy WebApp Gerenciador/Interface
1- Criar um WebApp
```cmd
   Nome: appinterface001 (usar seu nome exclusivo)
   Publish: Code
   Runtime Stack: .NET6
   Região: east-us
   Escolher AppServicePlan já criado
```
2- Deploy da aplicação
Baixar o zip da aplicação em 
https://github.com/raphasi/imersaoazure

3- Realizar o deploy da aplicação para o WebApp
Abrir o Powershell ou Terminal e executar o seguinte comando:
```cmd
az login (ou utilizar o CloudShell)
az webapp deploy --resource-group rg-azure --name <app-name> --src-path DeploymentGerenciador.zip
```
4- Ajustar application settings 
   - Acessar o WebApp - Configuration
   - Application settings
   - New application settings
   - Add/Edit application settings
  ```cmd
   Name: ServiceUri:UrlApi
   Value: https://apim-tftec00001.azure-api.net (coletar a URL do APIM)
   SAVE
   ``` 

## STEP25 - Expor requests no APIM
1- Disponibilizar APIs externamente no APIM
   - Acessar o APIM criado
   - Acessar APIs
   - Em Create from definition, escolher a opção OpenAPI
   - Clicar em Select a file e importar o arquivo APICatalogo.openapi+json (baixado do diretório do github, dentro da pasta APICatalog)
   - Clicar em Create
   - Acessar em Design, a seção Backend
   - Clicar em editar HTTP(s) endpoint
   - Marcar a opção override e adicionar o endereço do WebApp (APIM - tftecapi01)
   - Exemplo: https://tftecapi000001.azurewebsites.net/
   - SAVE
   - Acessar a aba Settings
   - Apagar o conteúdo do campo Web service URL
   - Desmarcar a opção Subscription required
   - SAVE
   

## STEP26 - Container Registry
  ```cmd
   Nome: acrimagestftec01 (nome deve ser único)
   Região: brazil-south
   SKU: Standard
   ```

## STEP27 - Deploy Cluster AKS
  ```cmd
   Cluster present configuration: Standard
   Nome: aks-app01
   Região: australia-east
   AKS Pricing Tier: Standard
   Kubernetes version: Default
   Scale method: Autoscale
   Network configuration: Kubenet
   Container Registry:
   ```



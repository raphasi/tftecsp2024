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
                                       -Kind StorageV2
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
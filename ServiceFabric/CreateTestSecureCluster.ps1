# https://docs.microsoft.com/en-us/azure/service-fabric/service-fabric-tutorial-create-cluster-azure-ps
$outputFolder = "c:\temp\"

$region = "westeurope"
$certificateSubjectName = $("$clusterName.$region.cloudapp.azure.com")

$vaultName = "myVaultBlah99"
$vaultResourceGroupName = "Vaults"

$clusterName = "myclusterblah99"
$clusterResourceGroupName = "Clusters"
$clusterSize = 1

$vmUserName = "mambovibe"
$vmSize = "Standard_A4"

$pwd = "mambovibepassword" | ConvertTo-SecureString -AsPlainText -Force

Login-AzureRmAccount
#Select-AzureRmSubscription -SubscriptionId "XXXXXXXXXXXXXXXXXXXXXXXX"

cls

Write-Host "Starting key vault stuff..." -ForegroundColor Green

New-AzureRmResourceGroup -Name $vaultResourceGroupName -Location 'West Europe'
New-AzureRmKeyVault -VaultName $vaultName -ResourceGroupName $vaultResourceGroupName -Location $region -EnabledForDeployment

Write-Host "Starting cluster build..." -ForegroundColor Green

$cluster = New-AzureRmServiceFabricCluster -ResourceGroupName $clusterResourceGroupName `
                                -CertificateOutputFolder $outputFolder `
                                -CertificatePassword $pwd `
                                -CertificateSubjectName $certificateSubjectName `
                                -ClusterSize $clusterSize `
                                -KeyVaultName $vaultName `
                                -KeyVaultResouceGroupName $vaultResourceGroupName `
                                -Location $region `
                                -Name $clusterName `
                                -OS WindowsServer2016DatacenterwithContainers `
                                -VmPassword $pwd `
                                -VmSku $vmSize `
                                -VmUserName $vmUserName

$certPath = $cluster.Certificates.CertificateSavedLocalPath
$certificateThumbprint = $cluster.Certificates.CertificateThumbprint
$clusterManagementEndPoint = $cluster.Cluster.ManagementEndpoint
$url = new-object system.uri -ArgumentList $clusterManagementEndPoint
                             
Import-PfxCertificate -Exportable -CertStoreLocation Cert:\CurrentUser\My -FilePath $certPath -Password $pwd

Connect-ServiceFabricCluster -ConnectionEndpoint "$($url.Host):19000" `
                             -KeepAliveIntervalInSec 10 `
                             -X509Credential `
                             -ServerCertThumbprint $certificateThumbprint `
                             -FindType FindByThumbprint `
                             -FindValue $certificateThumbprint `
                             -StoreLocation CurrentUser `
                             -StoreName My

Get-ServiceFabricClusterHealth

#### https://4sysops.com/archives/how-to-create-an-azure-vm-with-the-arm-powershell-cmdlets/
param($NewHostName)



Write-Host "Running for $NewHostName"

. .\variables.ps1


#### Reserve a new public IPAddress.
$newPublicIpParams = @{
	'Name' = "$NewHostName-NICPIP"
	'ResourceGroupName' = $resourceGroupEnvironment
	'AllocationMethod' = 'Dynamic' ## Dynamic or Static
	#'DomainNameLabel' = 'test-domain'
	'Location' = $datacentreLocation
}
$publicIp = New-AzureRmPublicIpAddress @newPublicIpParams



#### Create a new virtual NIC
$newVNicParams = @{
	'Name' = "$NewHostName-MyNic"
	'ResourceGroupName' = $resourceGroupEnvironment
	'Location' = $datacentreLocation
}

#####
#####
#####  TODO  TODO  TODO - Find a way to specify the subnet on which to place the NIC - perhaps read this from a config file
$vNic = New-AzureRmNetworkInterface @newVNicParams -SubnetId $vNet.Subnets[0].Id -PublicIpAddressId $publicIp.Id



#### Start collecting core VM configuration settings
$newConfigParams = @{
	'VMName' = $NewHostName
	'VMSize' = 'Standard_A4'
}
$vm = New-AzureRmVMConfig @newConfigParams



#### Add the network interface to the VM.
$vm = Add-AzureRmVMNetworkInterface -VM $vm -Id $vNic.Id



##### Define the OS disk for the VM.
$storageAccount = Get-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup
$osDiskName = "$NewHostName"
$osDiskUri = $storageAccount.PrimaryEndpoints.Blob.ToString() + $storageAccountContainer + "/" + "$osDiskName.vhd"
$diskName = "$NewHostName.vhd"
$vm = Set-AzureRmVMOSDisk -VM $vm -Name $diskName -VhdUri $osDiskUri -CreateOption Attach -Windows


#### Now go ahead and create the VM
New-AzureRmVM -ResourceGroupName $resourceGroupEnvironment -Location $datacentreLocation -VM $vm
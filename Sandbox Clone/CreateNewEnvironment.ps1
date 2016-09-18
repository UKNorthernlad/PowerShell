### Login in Azure (this needs to be done twice - once for each version of Azure).
#Login-AzureRmAccount
#Add-AzureAccount

########################################################################
### Create a new VM based off a previously uploaded .vhd disk image. ###
########################################################################

. .\variables.ps1

Write-Host -ForegroundColor Green "Creating new container in blob storage and copy across the base image disk."

# Get a storage key to the storage account in preparation for copying data.
$saKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroup)[0].Value

# Get a reference to the source location which contains the blobs we want to copy.
$saContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $saKey

# Create the destination container to hold all the blob copies
$saContext | New-AzureStorageContainer -Name "$storageAccountContainer" -Permission Off -ErrorAction SilentlyContinue

#Get a reference to blobs in the source container.
$blobs = Get-AzureStorageBlob -Container $storageAccountContainerBaseImages -Context $saContext

#Copy blobs from one container to another.
$blobs | Start-AzureStorageBlobCopy -DestContainer "$storageAccountContainer" -DestContext $saContext


# Start-AzureStorageBlobCopy -SrcBlob "mydc01new2016530114114.vhd"  -SrcContainer vhdimages -DestContainer vhdimages -DestBlob "mydc01.vhd" -Context $saContext 

###
###
### Start the new environment creation
###
###
###

Write-Host -ForegroundColor Green "Creating a new resource group to hold all the new resources including network and VM."
# Create a new resource group
New-AzureRmResourceGroup -Name $resourceGroupEnvironment -Location $datacentreLocation

Write-Host -ForegroundColor Green "Creating the network."
# Create the network
. .\CreateNetwork.ps1

Write-Host -ForegroundColor Green "Creating the VM."
# Create each of the servers
. .\CreateServer.ps1 -NewHostName mydc01 # this is the name of the server we want to build.


# Things TODO
# 1. Setup Security Group ACL for network card to restrict access from the internet
# 2. Install the Azure Agent onto the newly imported machine and register this in Azure.
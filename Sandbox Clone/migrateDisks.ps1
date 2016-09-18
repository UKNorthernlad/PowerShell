# Login in Azure (this need to be done twice - once for each version of Azure).
############################################### Login-AzureRmAccount
############################################### Add-AzureAccount

. .\variables.ps1

# Some basic setup
Select-AzureSubscription -SubscriptionId $subscriptionGuid
New-AzureRmResourceGroup -Name $resourceGroup -Location $datacentreLocation -ErrorAction SilentlyContinue


####
#### Make copies of production/staging servers and upload these to Azure
####

# 1 - Stop existing physical or virtual machine and make a Hyper-V .vhd disk file.
# Use standard P2V tools for making physical to virutal disks.
# Convert existing VMWare disks to Hyper-V format using the Microsoft Virtual Machine Converter 3.0 tool set.
# http://www.microsoft.com/en-gb/download/details.aspx?id=42497
# Assuming the Microsoft Virtual Machine Converter 3.0 tool set is installed on your machine.
# Import-Module "C:\Program Files\Microsoft Virtual Machine Converter\MvmcCmdlet.psd1"

# Ensure you have copied the *.vmdk and *-flat.vdmk files. The following command needs access to both. Specify the *.vmdk file as the source and not the *-flat.vmdk file.
# See http://www.sumnone.com/post/2015/04/03/Simple-Conversion-Mistake-from-VMDK-to-VHD-VHDX for more details.
# ConvertTo-MvmcVirtualHardDisk -SourceLiteralPath c:\temp\VM-disk1.vmdk -VhdType FixedHardDisk -VhdFormat vhd -destination c:\temp\

# 2 - Create a remote blob store and container
New-AzureRmStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroup -Location $datacentreLocation -SkuName "Standard_LRS"  -ErrorAction SilentlyContinue
$saKey = (Get-AzureRmStorageAccountKey -Name $storageAccountName -ResourceGroupName $resourceGroup)[0].Value
$SourceContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $saKey
$SourceContext | New-AzureStorageContainer -Name $storageAccountContainerBaseImages -Permission Off -ErrorAction SilentlyContinue

# 3 - Upload .vhd file to Azure storage account
# Upload the .vhd to the Azure storage account in the specified container.
Add-AzureRmVhd -ResourceGroupName $resourceGroup -Destination "$storageAccountUrl/$storageAccountContainerBaseImages/$vhdName" -LocalFilePath "$vhdLocation\$vhdName" -Overwrite -Debug



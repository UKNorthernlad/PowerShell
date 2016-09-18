# https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-windows-capture-image/

Add-AzureRmAccount
#Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint "0123456789ABCDEF0123456789ABCDEF" -ApplicationId "xxxxxxxxxxx guid guid guid xxxxxxxxxxx" -TenantId "xxxxxxxxxxx guid guid guid xxxxxxxxxxx"

Select-AzureRmSubscription -SubscriptionId "xxxxxxxxxxx guid guid guid xxxxxxxxxxx"

$ResourceGroupName = "DemoRG"
$hostname = "vmtest01"
$saveImageContainer = "vhdimages"

$result = Read-Host "Have you sysprepped the machine you want to image (Y or N)?"
if (-not ($result -eq "y" -or $result -eq "Y"))
{
    Write-Host "You'll need to sysprep the machine first. See https://azure.microsoft.com/en-gb/documentation/articles/virtual-machines-windows-capture-image/"
    exit
}

## Doing the do...
Write-Host "De-provisioning the VM...."
Stop-AzureRmVM -ResourceGroupName $ResourceGroupName -Name $hostname -Force


# You need to set the status of the virtual machine in Azure to Generalized as running Sysprep.exe on it's own doesn't do this.
# The generalized state will not be shown on the portal but you can verify it by using Get-AzureRmVM.
Write-Host "Marking the VM as Generalized aka Sysprepped..."
Set-AzureRmVm -ResourceGroupName $ResourceGroupName -Name $hostname -Generalized

# Capture the virtual machine image to a destination storage container.
# It will be created in the same storage account as that of the original virtual machine.
# It will be named something like: https://blah.blob.core.windows.net/system/Microsoft.Compute/Images/vhdimages/YourTemplatePrefix-osDisk.someguid.vhd
# To confirm the location, open the .json template which this command produces and see the location listed at resources > storageProfile > osDisk > image > uri.
Save-AzureRmVMImage -ResourceGroupName $ResourceGroupName -VMName $hostname -DestinationContainerName $saveImageContainer -VHDNamePrefix YourTemplatePrefix -Path c:\temp\output.json -Overwrite




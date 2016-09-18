# Variables you might want to change
$subscriptionGuid="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" # change this to reflect the GUID of your Azure subscription
$resourceGroup="Base" # Name of the Resource Group into which a storage account to upload to is created. Will be created if it does not exist already.
$datacentreLocation="westeurope" # choose your datacentre to store all your stuff.

$storageAccountName="xxxxxxxxx" # Name of the Storage Account into which .vhd files are uploaded. Will be created if it does not exist already.
$storageAccountContainerBaseImages="vhdimages" # Container on the storage account into which the image is uploaded to.


$environmentname="agentx" # This forms part of the container name into which .vhd files are copied prior to making a new virtual machine. Create a unique name here (keep it short and lower case).

# The location of the .vhd file you want to upload and it's location on the local machine.
$vhdName="dc01.vhd"
$vhdLocation="c:\temp"


#################### Don't change the stuff below here.
$storageAccountUrl="https://$storageAccountName.blob.core.windows.net"
$storageAccountContainer="$environmentname-vhds"

$resourceGroupEnvironment = $environmentname
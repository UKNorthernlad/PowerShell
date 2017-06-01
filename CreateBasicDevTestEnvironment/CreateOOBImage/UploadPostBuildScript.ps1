$StorageContainerName = 'scripts'
$fileToUpload = 'doWork.ps1'

$storageAccountName = (find-azurermresource -Tag @{'buildScriptStorage'='true'}).Name


$StorageAccount = (Get-AzureRmStorageAccount | Where-Object{$_.StorageAccountName -eq $storageAccountName})


$StorageAccountContext = $StorageAccount.Context


$container = New-AzureStorageContainer -Name $StorageContainerName -Context $StorageAccountContext -Permission Container -ErrorAction SilentlyContinue *>&1



Set-AzureStorageBlobContent -File $fileToUpload -Blob $fileToUpload -Container $StorageContainerName -Context $StorageAccountContext -Force -ErrorAction Stop
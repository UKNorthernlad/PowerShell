#login-azurermaccount
#select-azurermsubscription -SubscriptionName "[Sub Name]"
 
$resourceGroupName = "[RG Name]"
$recoveryServiceVaultName = "[Vault Name]"

$vault = Get-AzureRmRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name $recoveryServiceVaultName

Set-AzureRmRecoveryServicesVaultContext -Vault $vault

$containers = Get-AzureRmRecoveryServicesBackupContainer -ContainerType AzureSQL -FriendlyName $vault.Name

ForEach ($container in $containers)
{
   $items = Get-AzureRmRecoveryServicesBackupItem -container $container -WorkloadType AzureSQLDatabase  
    
   ForEach ($item in $items)
   {
      # Remove the backups from the vault
      ###################################
      Disable-AzureRmRecoveryServicesBackupProtection -item $item -RemoveRecoveryPoints -ea SilentlyContinue
   }

   Unregister-AzureRmRecoveryServicesBackupContainer -Container $container
}

# Delete the recovery services vault
####################################
Remove-AzureRmRecoveryServicesVault -Vault $vault

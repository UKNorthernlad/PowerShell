# RemoveBackupVault

When you create a Backup Vault in Azure for backing up cloud and on-prem resources such as VMs and SQL databases,
the items which you backup are created as their own configuration entries in the vault.
If you want to delete the vault you need to remove all the config items first.

However sometimes a problem exists where the Portal properties page tells you there are no items in the vault yet
when you try to delete it, you receive an error informing you to check configuration items are removed.

The problem seems to lie in the fact that the Portal status screen does not show Azure SQL PaaS database
containers in the Vault AND you had one or more SQL PaaS databases created at the same time as you created the
Backkup Vault. In this situation, a configuration container is created in the Vault (even if you didn't back anything up),
but it's not displayed.

To solve this issue, you can use PowerShell to display any SQL PaaS containers, delete them and then remove the Backup Vault.
The script in this folder will do that for you.

# Create a VM sandboxed in it's own Virtual Network from a .vhd image.

These scripts can be used to upload a .vhd disk image (i.e. Hyper-V format) from your local machine to Azure Blob Storage then to create a new VM from it. The new machine will be sandboxed in it's own virtual network.

If your existing virtual machine is in VMWare .vmdk format you can use the [Microsoft Virtual Machine Converter 3.0][ToolSet] tool set to convert it. Ensure you have both the *.vmdk and *-flat.vdmk files available else the conversion will fail.

None of these scripts are what you would call highly polished - they do the job they are intended to!

## How to use the scripts.

There are only three scripts you need to be concerned with initially.

- Variables.ps1 - Use this to set key things like the subscription you want to work with, names of resources groups and storage acccounts etc.
- MigrateDisks.ps1 - This is use to upload the "gold" .vhd image from your local machine to Azure. You'll only need to do this once or when you need to refresh your image in Azure.
- CreateNewEnvironment.ps1 - You run this each time you want to build a new environment based on your gold image. 

To build a new environment:

1. Update Variables.ps1 to set your SubscriptionGuid & ResourceGroupName etc.
2. Run MigrateDisks.ps1. You'll only need to do this once.
3. Run CreateNewEnvironment.ps1. Ensure you set the $environmentname variable in Variables.ps1 to something unique each time you create a new environment as this will be prefixed to the resource group which will hold your new virtual machine.

<!-- LINKS -->
[ToolSet]: http://www.microsoft.com/en-gb/download/details.aspx?id=42497
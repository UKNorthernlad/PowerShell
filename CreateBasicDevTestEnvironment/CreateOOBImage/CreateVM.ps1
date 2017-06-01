#Requires -Version 3.0
#Requires -Module AzureRM.Resources
#Requires -Module Azure.Storage
#EM

Param(
	[string] $ResourceGroupName = "Servers",
    [string] $ServerName = "server1",
    [string] $ResourceGroupLocation = "WestEurope",
    [switch] $UploadArtifacts,
    [string] $StorageAccountName,
    [string] $StorageContainerName = $ResourceGroupName.ToLowerInvariant() + '-stageartifacts',
    [string] $TemplateFile = 'CreateVM.json',
    [string] $ArtifactStagingDirectory = '.',
    [string] $DSCSourceFolder = 'DSC',
    [switch] $ValidateOnly
)

Import-Module Azure -ErrorAction SilentlyContinue

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(" ","_"), "2.9.5")
} catch { }


if ((Get-AzureRMVM -ResourceGroupName $ResourceGroupName -Name $ServerName -ErrorAction SilentlyContinue) -ne $null)
{
    Write-Error "Machine $ServerName in $ResourceGroupName already exists. Try again using the -ServerName parameter and specify the name of a new machine."
    return
}

Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @("  " * $Depth + $_.Code + ": " + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

$OptionalParameters = New-Object -TypeName Hashtable
$TemplateFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateFile))
#$TemplateParametersFile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $TemplateParametersFile))

# Create or update the resource group using the specified template file and template parameters file
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -Verbose -Force -ErrorAction Stop

$ErrorMessages = @()
if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName `
                                                                                  -TemplateFile $TemplateFile `
                                                                                  -TemplateParameterFile $TemplateParametersFile `
                                                                                  @OptionalParameters `
                                                                                  -Verbose)
}
else {

    
    $creationParameters = @{"storageAccountName"="$((find-azurermresource -Tag @{'buildScriptStorage'='true'}).Name)";"virtualMachineName"=$ServerName} 

    New-AzureRmResourceGroupDeployment -Name ((Get-ChildItem $TemplateFile).BaseName + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
                                       -ResourceGroupName $ResourceGroupName `
                                       -TemplateFile $TemplateFile `
                                       -TemplateParameterObject $creationParameters `
                                       @OptionalParameters `
                                       -Force -Verbose `
                                       -ErrorVariable ErrorMessages
							
						
    $ErrorMessages = $ErrorMessages | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") }
}
if ($ErrorMessages)
{
    "", ("{0} returned the following errors:" -f ("Template deployment", "Validation")[[bool]$ValidateOnly]), @($ErrorMessages) | ForEach-Object { Write-Output $_ }
}
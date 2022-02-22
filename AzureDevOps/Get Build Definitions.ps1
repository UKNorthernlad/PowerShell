# Only change the following  values:
$PAT = "gdfsgdfsge5436ygdgrthyt67rhfyht"
$invokeURL = "https://dev.azure.com/myorg/demos" + "/_apis/build/definitions?api-version=6.0"

# Don't change anything below here:

function Build-Credential
{
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true)]
        [string]$PATToken
    )

    # Build the Basic Header String (we don't need a username
    $clearAuthHeader = ":" + $PAT

    # Get the raw bytes of the clearAuthHeader
    $clearAuthHeaderBytes = [System.Text.Encoding]::UTF8.GetBytes($clearAuthHeader)

    # Base64 Encode the raw bytes 
    return [System.Convert]::ToBase64String($clearAuthHeaderBytes)
}


# Create a credential object
$Credential = Build-Credential -PATToken $PAT

$headers = @{
 "Content-Type"="application/json"
 "Authorization"= "Basic $Credential"
 }

# Invoke the request.
# REST API Reference = https://docs.microsoft.com/en-us/rest/api/azure/devops/build/definitions/list?view=azure-devops-rest-6.0
$buildDefinitions = Invoke-RestMethod -Method Get -Uri $invokeURL -Headers $headers
Write-Host "`nThe following Build Definitions are available:`n"

foreach ($buildDefinition in $buildDefinitions.value)
{
    Write-Host "Build Defintion ID = "   $($buildDefinition.id)
    Write-Host "Build Defintion name = " $($buildDefinition.name)
    Write-Host "Build Defintion uri = "  $($buildDefinition.uri)
    Write-Host "Build Defintion url = "  $($buildDefinition.url)

    Write-Host  
}
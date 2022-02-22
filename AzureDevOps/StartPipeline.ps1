# Only change the following  values:
$PAT = "gdfsgdfsge5436ygdgrthyt67rhfyht"
$invokeURL = "https://dev.azure.com/myorg/demos" + "/_apis/pipelines/61/runs?api-version=6.1-preview.1"

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

# Invoke a new build
# REST API Reference = https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/queue?view=azure-devops-rest-6.0
# Start a new Build a given Build Defintion ID from the previous call - harded to 61 in this example

# Create the HTTP Post body which contains any parameters or variables you want to pass,
$body = '
{
    "templateParameters": {
        "enableImportantThing": "True",
        "targetHostPool": "Pool3",
        "zoneNumber": "Z3"
    }
}
'

# Invoke the request.
Invoke-RestMethod -Method POST -Uri $invokeURL  -Body $body -Headers $headers
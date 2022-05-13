[string]$Organization = "myOrg"
[string]$Project = "SomeProjectName"
[string]$PersonalAccessToken = "qwertyuiopasdfghjklzxcvbnm1234567890"
[bool]$clearQueue = $true 
    
$getBuildsURL = "https://dev.azure.com/$Organization/$Project" + "/_apis/build/builds?statusFilter=notStarted&api-version=7.1-preview.7"


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
$Credential = Build-Credential -PATToken $PersonalAccessToken

$headers = @{
 "Content-Type"="application/json"
 "Authorization"= "Basic $Credential"
 }

# Invoke the request.
# REST API Reference = https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/get?view=azure-devops-rest-7.1
$builds = Invoke-RestMethod -Method Get -Uri $getBuildsURL -Headers $headers

$status = "`nThere are currently $($buildDefinitions.value.Count) builds in the 'notStarted' state located in https://dev.azure.com/" + $Organization + "/" + $Project + ".`n"
Write-Host $status
Write-Host "Build ID numbers are:" $buildDefinitions.value.id


if($clearQueue)
{
  Write-Host "`nDeleting the following builds...`n"
  foreach ($queuedBuild in $buildDefinitions.value.id)
  {
    # REST API Reference = https://docs.microsoft.com/en-us/rest/api/azure/devops/build/builds/delete?view=azure-devops-rest-7.1
    $deleteBuildsURL = "https://dev.azure.com/$Organization/$Project" + "/_apis/build/builds/" + "$queuedBuild" + "?api-version=7.1-preview.7"
    Write-Host $deleteBuildsURL
    $result = Invoke-RestMethod -Method DELETE -Uri $deleteBuildsURL -Headers $headers   
  }
}

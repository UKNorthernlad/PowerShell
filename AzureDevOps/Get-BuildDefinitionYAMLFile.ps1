# Only change the following  values:
$PAT = "XXXXXX"
$invokeURLBase = "https://dev.azure.com/orgname/projectname"

#########################

# Don't change anything below here:

$invokeURL = $invokeURLBase + "/_apis/build/definitions?api-version=6.0"



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

Write-Host "Basics"
Write-Host "XXXXXX"

foreach ($buildDefinition in $buildDefinitions.value)
{
    $buildDefinitionFull = Invoke-RestMethod -Method Get -Uri $buildDefinition.url -Headers $headers

    Write-Host "Build Defintion ID   = " $($buildDefinition.id)
    Write-Host "Build Defintion name = " $($buildDefinition.name)
    Write-Host "Build Defintion url  = " $($buildDefinition.url)
    Write-Host "YAML Repository      = " $($buildDefinitionFull.repository.url)

    $isYAMLPipeline = $true
    if($buildDefinitionFull.process.yamlFilename -eq $null) {
               $isYAMLPipeline = $false
               Write-Host "YAML FileName        =  None - This is a classic pipeline."
    } else {
               Write-Host "YAML FileName        = "  $($buildDefinitionFull.process.yamlFilename)
    }

    Write-Host 

    #Write-Host "RAW Build Definition"
    #Write-Host "XXXXXXXXXXXXXXXXXXXX"
    #$BuildDefinition

    #Write-Host "RAW Full Build Definition"
    #Write-Host "XXXXXXXXXXXXXXXXXXXXXXXXX"
    #$buildDefinitionFull
    
    if($isYAMLPipeline) {

    # Construct the URL to get the raw file contents.
   
    # Determine the branch name
    $branchName = ($buildDefinitionFull.repository.defaultBranch -split "/")[-1]

    $pipelineYamlRawFileURL = $invokeURLBase + "/_apis/sourceProviders/" + $buildDefinitionFull.repository.type + "/filecontents?repository=" + $buildDefinitionFull.repository.name + "&commitOrBranch=" + $branchName + "&api-version=5.0-preview.1&path=%2F" + $buildDefinitionFull.process.yamlFilename


    Write-Host "YAML Raw File"
    Write-Host "XXXXXXXXXXXXX"
    #Write-Host $pipelineYamlRawFileURL
    Write-Host
    $pipelineYamlRawFile = Invoke-RestMethod -Method Get -Uri $pipelineYamlRawFileURL -Headers $headers
    #$pipelineYamlRawFile
    $escaptedPipelineYamlRawFile = $pipelineYamlRawFile.Replace("`n","\n") 
 $escaptedPipelineYamlRawFile
    }

    Write-Host 
    Write-Host 
    Write-Host 
    Write-Host 
    Write-Host 
    Write-Host 
}

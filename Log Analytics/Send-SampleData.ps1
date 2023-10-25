# Taken from https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-code?tabs=powershell


##################################################
# TODO: This script has not been tested end to end 
##################################################

Add-Type -AssemblyName System.Web

### Step 0: Set variables required for the rest of the script.

# information needed to authenticate to AAD and obtain a bearer token
$tenantId = "XXXXXX-XXXXXXX-XXXXXXX-XXXXXXX" #Tenant ID the data collection endpoint resides in
$appId = "XXXXXX-XXXXXXX-XXXXXXX-XXXXXXX" #Application ID created and granted permissions
$appSecret = "XXXXXXXXXXXX" #Secret created for the application

# information needed to send data to the DCR endpoint
$dceEndpoint = "https://XXXXX-XXXX.westeurope-1.ingest.monitor.azure.com" #the endpoint property of the Data Collection Endpoint object
$dcrImmutableId = "dce-XXXXXX-XXXXXXX-XXXXXXX" #the immutableId property of the DCR object
$streamName = "MyTableRawData" #name of the stream in the DCR that represents the destination table


### Step 1: Obtain a bearer token used later to authenticate against the DCE.

$scope= [System.Web.HttpUtility]::UrlEncode("https://monitor.azure.com//.default")   
$body = "client_id=$appId&scope=$scope&client_secret=$appSecret&grant_type=client_credentials";
$headers = @{"Content-Type"="application/x-www-form-urlencoded"};
$uri = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"

$bearerToken = (Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers).access_token


### Step 2: Create some sample data. 

$currentTime = Get-Date ([datetime]::UtcNow) -Format O
$staticData = @"
[
{
    "Time": "$currentTime",
    "Computer": "Computer1",
    "AdditionalContext": {
        "InstanceName": "user1",
        "TimeZone": "Pacific Time",
        "Level": 4,
        "CounterName": "AppMetric1",
        "CounterValue": 15.3    
    }
},
{
    "Time": "$currentTime",
    "Computer": "Computer2",
    "AdditionalContext": {
        "InstanceName": "user2",
        "TimeZone": "Central Time",
        "Level": 3,
        "CounterName": "AppMetric1",
        "CounterValue": 23.5     
    }
}
]
"@;


### Step 3: Send the data to the Log Analytics workspace via the DCE.

$body = $staticData;
$headers = @{"Authorization"="Bearer $bearerToken";"Content-Type"="application/json"};
$uri = "$dceEndpoint/dataCollectionRules/$dcrImmutableId/streams/$($streamName)?api-version=2021-11-01-preview"

$uploadResponse = Invoke-RestMethod -Uri $uri -Method "Post" -Body $body -Headers $headers
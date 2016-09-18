cls

function GetReport
{
    param($AgentId = "$((Get-DscLocalConfigurationManager).AgentId)", $serviceURL = "https://pullserver:8080/PSDSCPullServer.svc")

    $requestUri = "$serviceURL/Nodes(AgentId= '$AgentId')/Reports"

    $request = Invoke-WebRequest -Uri $requestUri  -ContentType "application/json;odata=minimalmetadata;streaming=true;charset=utf-8" -UseBasicParsing -Headers @{Accept = "application/json";ProtocolVersion = "2.0"} -ErrorAction SilentlyContinue -ErrorVariable ev
    
    $object = ConvertFrom-Json $request.content
   
    return $object.value
}

$reportdata = GetReport

# Examples of what you can do with the data include:
#$reportdata | Sort-Object -Property StartTime
# or 
#$reportdata[-11].StatusData | ConvertFrom-Json


####### 

#Troubleshooting - https://msdn.microsoft.com/en-us/powershell/dsc/troubleshooting
###############
(Get-DscConfigurationStatus).ResourcesInDesiredState
(Get-DscConfigurationStatus).ResourcesNotInDesiredState









# Ingest logs into Log Analytics using PowerShell
# https://learn.microsoft.com/en-us/azure/azure-monitor/logs/set-up-logs-ingestion-api-prerequisites
# https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal

# Display which MSGraph permissions are required to call the API for a given Graph cmdlet.
# Find-MgGraphCommand -command Get-MgUser | Select -First 1 -ExpandProperty Permissions



##############################################################################
# TODO: This script still needs code to create a custom table to log data into
##############################################################################




#Install-module -Name Microsoft.Graph

#region Variables
$TenantId                              = "XXXXx-XXXXX-XXXXXXXXX" #XXXXXX.onmicrosoft.com

# AzureAD App registration
$AzureAppName                          = "Log-Ingestion-App99"
$AzAppSecretName                       = "Log-Ingestion-Appsecret"

# Log Analytics workspace
$LogAnalyticsSubscription              = "XXXXX-XXXXX-XXXXXX-XXXXX-XXXXX"
$LogAnalyticsResourceGroup             = "Logs"
$LoganalyticsWorkspaceName             = "DefaultLogs"
$LoganalyticsLocation                  = "westeurope"

# Data collection endpoint
$AzDceName                             = "dce99"
$AzDceResourceGroup                    = "rg-dce99"

# Data collection rule
$AzDcrResourceGroup                    = "rg-dcr-log-ingestion-demo"
$AzDcrPrefix                           = "demo"

$VerbosePreference                     = "SilentlyContinue"  # "Continue"

#endregion 

#-------------------------------------------------------------------------------------
# Connect to Azure
#-------------------------------------------------------------------------------------
Connect-AzAccount -Tenant $TenantId -WarningAction SilentlyContinue

# Get access token
$AccessToken = Get-AzAccessToken -ResourceUrl https://management.azure.com/
$AccessToken = $AccessToken.Token

# Build headers for Azure REST API with access token
$Headers = @{
                "Authorization"="Bearer $($AccessToken)"
                "Content-Type"="application/json"
            }

#-------------------------------------------------------------------------------------
# Connect to Microsoft Graph
#-------------------------------------------------------------------------------------
    $MgScope = @(
                    "Application.ReadWrite.All",`
                    "Directory.Read.All",`
                    "Directory.AccessAsUser.All",
                    "RoleManagement.ReadWrite.Directory"
                )

Connect-MgGraph -TenantId $TenantId -Scopes $MgScope

#-------------------------------------------------------------------------------------
# Create Log Analytics Workspace
#-------------------------------------------------------------------------------------
New-AzResourceGroup -Name $LogAnalyticsResourceGroup -Location $LoganalyticsLocation

New-AzOperationalInsightsWorkspace -Location $LoganalyticsLocation -Name $LoganalyticsWorkspaceName -Sku PerGB2018 -ResourceGroupName $LogAnalyticsResourceGroup

$LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
$LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId


#-------------------------------------------------------------------------------------
# Create AzureAD Application registration
#-------------------------------------------------------------------------------------
Write-Output "Validating Azure App [ $($AzureAppName) ]"
$AppCheck = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'" -ErrorAction Stop

If ($AppCheck -eq $null)
{
    Write-Output ""
    Write-host "Creating AzureAD Application Registration [ $($AzureAppName) ]"
    $AzureApp = New-MgApplication -DisplayName $AzureAppName
}

#-------------------------------------------------------------------------------------
# Create service principal on AzureAD Application
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Validating Azure Service Principal on App [ $($AzureAppName) ]"
$AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"

$AppId    = $AppInfo.AppId
$ObjectId = $AppInfo.Id

$ServicePrincipalCheck = Get-MgServicePrincipal -Filter "AppId eq '$AppId'"
If ($ServicePrincipalCheck -eq $null)
{
    Write-Output ""
    Write-host "Creating Azure Service Principal on App [ $($AzureAppName) ]"
    $ServicePrincipal = New-MgServicePrincipal -AppId $AppId
}

#-------------------------------------------------------------------------------------
# Create secret on AzureAD Application
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Validating Azure Secret on App [ $($AzureAppName) ]"
$AppInfo  = Get-MgApplication -Filter "AppId eq '$AppId'"

$AppId    = $AppInfo.AppId
$ObjectId = $AppInfo.Id

If ($AzAppSecretName -notin $AppInfo.PasswordCredentials.DisplayName)
{
    Write-Output ""
    Write-host "Creating Azure Secret on App [ $($AzureAppName) ]"

    $passwordCred = @{
                        displayName = $AzAppSecretName
                        endDateTime = (Get-Date).AddYears(1)
                     }

    $AzAppSecret = (Add-MgApplicationPassword -applicationId $ObjectId -PasswordCredential $passwordCred).SecretText
    
    Write-Output ""
    Write-Output "Secret with name [ $($AzAppSecretName) ] created on app [ $($AzureAppName) ]"
    Write-Output $AzAppSecret
    Write-Output ""
    Write-Output "AppId for app [ $($AzureAppName) ] is"
    Write-Output $AppId
}

#-------------------------------------------------------------------------------------
# Create a resource group for data collection endpoints (DCE) in the same region as the Log Analytics workspace
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Validating Azure resource group exist [ $($AzDceResourceGroup) ]"
try {
        Get-AzResourceGroup -Name $AzDceResourceGroup -ErrorAction Stop
    } catch {
            Write-Output ""
            Write-Output "Creating Azure resource group [ $($AzDceResourceGroup) ]"
            New-AzResourceGroup -Name $AzDceResourceGroup -Location $LoganalyticsLocation
    }

#-------------------------------------------------------------------------------------
# Create a resource group for data collection rules (DCR) in the same region as the Log Analytics workspace
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Validating Azure resource group exist [ $($AzDcrResourceGroup) ]"
try {
        Get-AzResourceGroup -Name $AzDcrResourceGroup -ErrorAction Stop
    } 
    catch
    {
        Write-Output ""
        Write-Output "Creating Azure resource group [ $($AzDcrResourceGroup) ]"
        New-AzResourceGroup -Name $AzDcrResourceGroup -Location $LoganalyticsLocation
    }

#-------------------------------------------------------------------------------------
# Create data collection endpoint
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Validating data collection endpoint exist [ $($AzDceName) ]"
    
$DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
Try
{
    Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers
}
Catch
{
    Write-Output ""
    Write-Output "Creating/updating DCE [ $($AzDceName) ]"

    $DceObject = [pscustomobject][ordered]@{
                                properties = @{
                                                description = "DCE for LogIngest to LogAnalytics $LoganalyticsWorkspaceName"
                                                networkAcls = @{
                                                                    publicNetworkAccess = "Enabled"

                                                                }
                                                }
                                location = $LogAnalyticsLocation
                                name = $AzDceName
                                type = "Microsoft.Insights/dataCollectionEndpoints"
                            }

    $DcePayload = $DceObject | ConvertTo-Json -Depth 20

    $DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"

    Try
    {
        Invoke-WebRequest -Uri $DceUri -Method PUT -Body $DcePayload -Headers $Headers
    }
    Catch
    {
    }
}
    
#-------------------------------------------------------------------------------------
# Sleeping 1 min to let Azure AD replicate before delegation
#-------------------------------------------------------------------------------------

# Write-Output "Sleeping 1 min to let Azure AD replicate before doing delegation"
Start-Sleep -s 60

#-------------------------------------------------------------------------------------
# Grant the Azure app permissions to the Log Analytics workspace
# Needed for table management - not needed for log ingestion - for simplicity, it's set up when there's one app
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on the Log Analytics workspace [ $($LoganalyticsWorkspaceName) ]"

$LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup

$LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

$ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
$DcrRgResourceId          = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

# Contributor on Log Analytics workspace
$guid = (new-guid).guid
$ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
$roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
$roleUrl = "https://management.azure.com" + $LogAnalyticsWorkspaceResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
$roleBody = @{
                properties = @{
                roleDefinitionId = $roleDefinitionId
                principalId      = $ServicePrincipalObjectId
                scope            = $LogAnalyticsWorkspaceResourceId
                }
            }

$jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                  Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }

#-------------------------------------------------------------------------------------
# Grant the AzureAD Applications permissions to the DCR resource group
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Setting Contributor permissions for app [ $($AzureAppName) ] on resource group [ $($AzDcrResourceGroup) ]"

$ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
$AzDcrRgResourceId        = (Get-AzResourceGroup -Name $AzDcrResourceGroup).ResourceId

# Contributor
$guid = (new-guid).guid
$ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
$roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
$roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
    
$roleBody = @{
                properties = @{
                roleDefinitionId = $roleDefinitionId
                principalId      = $ServicePrincipalObjectId
                scope            = $AzDcrRgResourceId
                }
            }

$jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

            $result = try
                {
                    Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
                }
            catch
                {
                }

Write-Output ""
Write-Output "Setting Monitoring Metrics Publisher permissions for app [ $($AzureAppName) ] on RG [ $($AzDcrResourceGroup) ]"

# Monitoring Metrics Publisher
$guid = (new-guid).guid
$monitorMetricsPublisherRoleId = "3913510d-42f4-4e42-8a64-420c390055eb"
$roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($monitorMetricsPublisherRoleId)"
$roleUrl = "https://management.azure.com" + $AzDcrRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
$roleBody = @{
                properties = @{
                roleDefinitionId = $roleDefinitionId
                principalId      = $ServicePrincipalObjectId
                scope            = $AzDcrRgResourceId
                }
            }

$jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

$result = try
            {
            Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
            }
            catch
            {
            }

#-------------------------------------------------------------------------------------
# Grant the Azure app permissions to the DCE resource group
#-------------------------------------------------------------------------------------

Write-Output ""
Write-Output "Setting Contributor permissions for app [ $($AzDceName) ] on RG [ $($AzDceResourceGroup) ]"

$ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
$AzDceRgResourceId        = (Get-AzResourceGroup -Name $AzDceResourceGroup).ResourceId

# Contributor
$guid = (new-guid).guid
$ContributorRoleId = "b24988ac-6180-42a0-ab88-20f7382dd24c"  # Contributor
$roleDefinitionId = "/subscriptions/$($LogAnalyticsSubscription)/providers/Microsoft.Authorization/roleDefinitions/$($ContributorRoleId)"
$roleUrl = "https://management.azure.com" + $AzDceRgResourceId + "/providers/Microsoft.Authorization/roleAssignments/$($Guid)?api-version=2018-07-01"
$roleBody = @{
                properties = @{
                roleDefinitionId = $roleDefinitionId
                principalId      = $ServicePrincipalObjectId
                scope            = $AzDceRgResourceId
                }
            }

$jsonRoleBody = $roleBody | ConvertTo-Json -Depth 6

$result = try
            {
                Invoke-RestMethod -Uri $roleUrl -Method PUT -Body $jsonRoleBody -headers $Headers -ErrorAction SilentlyContinue
            }
            catch
            {
            }

#-----------------------------------------------------------------------------------------------
# Summarize environment details
#-----------------------------------------------------------------------------------------------

# AzureAD
Write-Output ""
Write-Output "Tenant Id:"
Write-Output $TenantId

# AzureAD Application
$AppInfo  = Get-MgApplication -Filter "DisplayName eq '$AzureAppName'"
$AppId    = $AppInfo.AppId
$ObjectId = $AppInfo.Id

Write-Output ""
Write-Output "Log Ingestion Azure App name:"
Write-Output $AzureAppName

Write-Output ""
Write-Output "Log Ingestion Azure App ID:"
Write-Output $AppId
Write-Output ""

If ($AzAppSecret)
{
    Write-Output "LogIngestion Azure App secret:"
    Write-Output $AzAppSecret
}
Else
{
    Write-Output "Log Ingestion Azure App secret:"
    Write-Output "N/A (new secret must be made)"
}

# Azure Service Principal for App
$ServicePrincipalObjectId = (Get-MgServicePrincipal -Filter "AppId eq '$AppId'").Id
Write-Output ""
Write-Output "Log Ingestion service principal Object ID for app:"
Write-Output $ServicePrincipalObjectId

# Azure Loganalytics
Write-Output ""
$LogWorkspaceInfo = Get-AzOperationalInsightsWorkspace -Name $LoganalyticsWorkspaceName -ResourceGroupName $LogAnalyticsResourceGroup
$LogAnalyticsWorkspaceResourceId = $LogWorkspaceInfo.ResourceId

Write-Output ""
Write-Output "Log Analytics workspace resource ID:"
Write-Output $LogAnalyticsWorkspaceResourceId

# DCE
$DceUri = "https://management.azure.com" + "/subscriptions/" + $LogAnalyticsSubscription + "/resourceGroups/" + $AzDceResourceGroup + "/providers/Microsoft.Insights/dataCollectionEndpoints/" + $AzDceName + "?api-version=2022-06-01"
$DceObj = Invoke-RestMethod -Uri $DceUri -Method GET -Headers $Headers

$AzDceLogIngestionUri = $DceObj.properties.logsIngestion[0].endpoint

Write-Output ""
Write-Output "Data collection endpoint name:"
Write-Output $AzDceName

Write-Output ""
Write-Output "DCE immutableId"
Write-Output $DceObj.properties.immutableId

Write-Output ""
Write-Output "Data collection endpoint Log Ingestion URI:"
Write-Output $AzDceLogIngestionUri
Write-Output ""
Write-Output "-------------------------------------------------"




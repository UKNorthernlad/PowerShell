# Good starter examples
# https://stackoverflow.com/questions/60769329/retrieve-api-permissions-of-azure-ad-application-via-powershell

# Well known GUID for MS 1st party appications
# e.g. 00000003-0000-0000-c000-000000000000 is the MS Graph API
# https://docs.microsoft.com/en-us/troubleshoot/azure/active-directory/verify-first-party-apps-sign-in

# This preview PowerShell module is needed as it provides access to read the OAuth API settings and Sign-In logs.
#Install-Module AzureADPreview
#Connect-AzureAD # -TenantId "41d74113-3369-4a4d-9f99-fb3d8553357b"

# Get the list of applications
$apps = Get-AzureADApplication
Write-Host "Number of Apps:" $apps.Count
Write-Host

foreach ($app in $apps)
{
    $servicePrincipal = Get-AzureADServicePrincipal -Filter "Appid eq '$($app.AppId)'"
    
    Write-Host "###########################################################################"
    Write-Output "Application Name       : $($app.DisplayName)"
    Write-Output "Application Id         : $($app.AppId)"
    Write-Output "Application Obj Id     : $($app.ObjectId)" 
    Write-Output "Service Principal Name : $($servicePrincipal.DisplayName)"
    Write-Output "Service Principal Id   : $($servicePrincipal.ObjectId)"
   

    # Created date is not available from Get-AzureADApplication so we must use Get-AzADApplication instead.
    # This means however that you'll need to login using Login-AzAccount
    # Login-AzAccount 
    #$createdDate = Get-Date -format R -Date ((Get-AzADApplication -ObjectId $app.AppId).CreatedDateTime)
    #Write-Output "App Created Date   : $createdDate"

    # Last Sign-in Date
    $mostRecentSignIn = Get-AzureADAuditSignInLogs -Filter "AppId eq '$($app.AppId)'" -Top 1
    if($mostRecentSignIn -eq $null)
    {
        $lastSignIn = "No recent sign-in records in the logs."
    } else
    { 
        $lastSignIn = Get-Date -format R -Date $mostRecentSignIn.CreatedDateTime
    }
    Write-Output "Last Sign-in Date      : $lastSignIn"

    # List out the APIs which this application is configured to use.
    $apis = $app.RequiredResourceAccess
    Write-Output ""
    Write-Output "API Permissions        :"
    foreach ($api in $apis)
    {
       # This is the display name of the API - its really the name of the Application display name in the originating tenant.
       $apiDisplayName = $sp.AppDisplayName
       $apiGUID = $api.ResourceAppId # This is the AppId of the application from the originating tenant.
       Write-Output "                         $apiDisplayName ($apiGUID)"  

       # List out the permissions configured as part of the API.
       $result = $api.ResourceAccess
       foreach ($item in $result)
       {
           # Get the display names for each of the permissions
           $sp = get-azureadserviceprincipal -Filter "AppId eq '$apiGUID'"
           $roleName  = ($sp.AppRoles | Where-Object {$_.Id -eq $item.Id}).Value
           $scopeName = ($sp.Oauth2Permissions | Where-Object {$_.Id -eq $item.Id}).Value

           # Internally "User Delegation" permissions are known as "Scope" permissions
           # and "Application" permissions are known as "Role".
           if($item.Type -eq "Scope") {Write-Output "                               User       : $scopeName ($($item.Id))"}
           if($item.Type -eq "Role")  {Write-Output "                               Application: $roleName ($($item.Id))"}
       }
       Write-Host ""
    }

    Write-Output ""

    Write-Output ""
    # Link in portal
    $link = "https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Overview/appId/$($app.AppId)/isMSAApp~/false"
    Write-Output "Link         : $link"
    Write-Host "###########################################################################"
    Write-Host ""


}



#################


# Get the permissions which the admin has granted
#Get-AzureADServicePrincipalOAuth2PermissionGrant -ObjectId 85e677c9-0ff2-4acf-9e1f-88cc7872427a





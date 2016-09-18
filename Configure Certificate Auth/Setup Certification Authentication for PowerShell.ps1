
# https://azure.microsoft.com/en-in/documentation/articles/resource-group-authenticate-service-principal/

# Setup
$cert = New-SelfSignedCertificate -CertStoreLocation "cert:\CurrentUser\My" -Subject "CN=PowerShellAccess" -KeySpec KeyExchange
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
Add-AzureRmAccount
# If you hav multiple subscriptions, choose the one you need.
# Select-AzureRMSubscription -SubscriptionId XXXXXXX
$azureAdApplication = New-AzureRmADApplication -DisplayName "PowerShellAccessApp" -HomePage "https://www.mypowershell.org" -IdentifierUris "https://www.mypowershell.org/shellaccess" -KeyValue $keyValue -KeyType AsymmetricX509Cert -EndDate $cert.NotAfter -StartDate $cert.NotBefore      
New-AzureRmADServicePrincipal -ApplicationId $azureAdApplication.ApplicationId

# Get-AzureRMRoleDefinition
New-AzureRmRoleAssignment -RoleDefinitionName "Owner" -ServicePrincipalName $azureAdApplication.ApplicationId.Guid

# Get guid values you'll need for logging in with.
#

# The GUID of your Tenant.
(Get-AzureRmSubscription -SubscriptionName "Visual Studio Ultimate with MSDN").TenantId
# 17055e0f-3f5e-4c13-9cdb-0db3aee2353c

# The GUID of the AD Application you just created.
(Get-AzureRmADApplication -IdentifierUri "https://www.mypowershell.org/shellaccess").ApplicationId
#15b68bc2-08d4-46dc-8a25-4383fedf1731

# The Thumbprint of the certificate on your local machine used to authenticate you.
(Get-ChildItem -Path cert:\CurrentUser\My\* -DnsName PowerShellAccess).Thumbprint
# 18C07A843EDA9B02F2033F9B1F94654F97E7EC8F

# Using it
# Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint "0123456789ABCDEF0123456789ABCDEF"-ApplicationId "guid" -TenantId "guid"


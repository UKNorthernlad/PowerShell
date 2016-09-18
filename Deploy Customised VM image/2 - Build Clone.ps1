$RG = "DemoRG"
$DCLocation = "WestEurope"

Add-AzureRmAccount
#Add-AzureRmAccount -ServicePrincipal -CertificateThumbprint "0123456789ABCDEF0123456789ABCDEF" -ApplicationId "guid" -TenantId "guid"

.\deploy.ps1 -subscriptionId guid -resourceGroupName $RG -resourceGroupLocation $DCLocation -deploymentName "Our Great Test" -templateFilePath .\template.json -parametersFilePath .\parameters.json 

#Test-AzureRmResourceGroupDeployment -ResourceGroupName "DemoRG" -TemplateFile .\template.json -TemplateParameterFile .\parameters.json 


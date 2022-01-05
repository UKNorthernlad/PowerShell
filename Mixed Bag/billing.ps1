cls

$billingPeriod = "202202" # this is the "next" month - i.e. when you will pay for stuff used this month.
$tag = "Cost Centre"
$costCentreValue = 0

$context = Get-AzContext

# Get-AzSubscription -SubscriptionId XXXX-XXXX-XXXXX-XXXX | Select-AzSubscription # Development


Write-Host -NoNewline "Running against resources in the current subscription "
Write-Host -ForegroundColor Yellow "'$($context.Name)'`n"
Write-Host "Use 'Get-AzSubscription -SubscriptionId XXXXXX-XXXXX-XXXXX-XXXXX' to change subscription.`n"
Write-Host "The following resources have no '$tag' tag assigned (excludes ResourceGroups):`n"

$resources = Get-AzResource

foreach ($item in $resources)
{
    # Checking for resources with Zero tags
    if($item.Tags -eq $null)
    {
       $costCentreValue = $null
    }
    else
    {
        $costCentreValue = $item.Tags[$tag]
    }
  
    if($costCentreValue -eq $null) # either there is no "Cost Centre" tag or it has no value
    {
      Write-Host ResourceName = $item.ResourceName
      Write-Host Kind = $item.Kind
      Write-Host ResourceGroupName = $item.ResourceGroupName
      Write-Host ResourceId = $item.ResourceId
      Write-Host Tag Pairs: $item.Tags
        
      $details = Get-AzConsumptionUsageDetail -BillingPeriodName $billingPeriod  -ResourceGroup $item.ResourceGroupName -InstanceName $item.ResourceName # | Sort-Object -Property UsageStart
      if($details -eq $null)
      {
        Write-Host "No billing information available for this resource or charges are not applicable for this resource type."
      } else {
        $total = 0
        $currencySymbol = ""
        foreach ($cost in $details)
        {
            $currencySymbol = $cost.Currency # all items should have the same currency
            $total = $total + $cost.PretaxCost   
        }
        Write-Host Cost during the Billing Period $billingPeriod = $total $currencySymbol
      }
      
      Write-Host
    }          
}


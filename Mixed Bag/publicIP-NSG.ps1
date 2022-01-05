cls

$context = Get-AzContext

# My Development
Get-AzSubscription -SubscriptionId XXXXX-XXXXX-XXXXX-XXXXX | Select-AzSubscription


Write-Host -NoNewline "Running against resources in the current subscription "
Write-Host -ForegroundColor Yellow "'$($context.Name)'`n"
Write-Host "Use 'Get-AzSubscription -SubscriptionId XXXXXX-XXXXX-XXXXX-XXXXX' to change subscription.`n"

$publicIPAddresses = Get-AzPublicIpAddress

foreach ($ip in $publicIPAddresses)
{
    Write-Host "XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
    Write-Host "Public VM IP Address ResourceName = $($ip.Name)"
    Write-Host "Resource Group Name = $($ip.ResourceGroupName)"
    $pip = $ip.IpAddress
    Write-Host "IP Address = $pip"  -ForegroundColor Yellow

    if($pip -eq "Not Assigned") {Write-Host; continue }
    $resourceId = (Split-Path -Parent (Split-Path -Parent $ip.IpConfiguration.Id)).Replace("\","/")
    $resourceType = (Split-Path -Leaf (Split-Path -Parent $resourceId ))

    switch ($resourceType)
    {
    'networkInterfaces' {
                $networkInterface = (Get-AzNetworkInterface -ResourceId $resourceId)
                Write-Host "Public IP $($ip.Name) maps to a Network Interface."
                Write-Host "   Network Interface = $($networkInterface.Name)"
                Write-Host "   Inside VM = $(Split-Path -Leaf ($networkInterface.VirtualMachine.id))"
                Write-Host "   NSG Name = $(Split-Path -Leaf ($networkInterface.NetworkSecurityGroup.Id))"  -ForegroundColor Green
                Write-Host "   NSG Resource Group = $($networkInterface.ResourceGroupName)"
                Write-Host
                break;
    }
    'loadBalancers' {
                Write-Host "Public IP $($ip.Name) maps to a Load Balancer."
                $resource = Get-AzResource -ResourceId $resourceId
                $loadBalancer = Get-AzLoadBalancer -Name $resource.Name -ResourceGroupName $resource.ResourceGroupName
 
                foreach ($backendPool in $loadBalancer.BackendAddressPools)
                {
                    Write-Host "PoolName = $($backendPool.Name)"
                    Write-Host " Backend Nodes: $($backendPool.BackendIpConfigurations.Count)"

                    foreach ($configuration in $backendPool.BackendIpConfigurations)
                    {
                        #Write-Host "    $($configuration.id)"
                        $parts =  $configuration.id -split "/"
  
                        # From the configuration, try to see if it resolves to a Scale Set
                        $ss = Get-AzVmss -ResourceGroupName $parts[4] -VMScaleSetName $parts[8]
                        
                        if($ss -ne $null) {
                            Write-Host "  Looks like a node in a Scale Set:"
                            Write-Host "   Scale Set Name = $($parts[8])"
                            Write-Host "   Resource Group = $($parts[4])"
                            
                            #Get the NSG that corresponds to this Scale Set
                            $nsgId = $ss.VirtualMachineProfile.NetworkProfile.NetworkInterfaceConfigurations.networksecuritygroup.id

                            #Write-host "   NSG Id         = $nsgId"
                            $parts =  $nsgId -split "/"
                            Write-Host "   NSG Name       = $($parts[8])" -ForegroundColor Green
                            Write-Host "   NSG RG         = $($parts[4])"
                        }  
                    }
                }
                break;
    }
    Default {Write-Host "Resource Type not yet supported."}
    }
}
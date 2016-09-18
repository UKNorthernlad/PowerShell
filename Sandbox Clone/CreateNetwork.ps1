##### Create a subnet
$newSubnetParams1 = @{
	'Name' = 'PrivateSubnet'
	'AddressPrefix' = '10.0.1.0/24'
}
$subnet1 = New-AzureRmVirtualNetworkSubnetConfig @newSubnetParams1

##### Create another subnet
$newSubnetParams2 = @{
	'Name' = 'PublicSubnet'
	'AddressPrefix' = '10.0.2.0/24'
}
$subnet2 = New-AzureRmVirtualNetworkSubnetConfig @newSubnetParams2

##### Create a network and add subnet created above
$newVNetParams = @{
	'Name' = "$resourceGroupEnvironment-vnet"
	'ResourceGroupName' = $resourceGroupEnvironment
	'Location' = $datacentreLocation
	'AddressPrefix' = '10.0.0.0/16'
}
$vNet = New-AzureRmVirtualNetwork @newVNetParams -Subnet $subnet1,$subnet2


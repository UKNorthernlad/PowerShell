# Writing logs to Log Analytics.

## Create-LogStore.ps1
This script (currently incomplete) will create a Log Analytics workspace and a Data Collection Endpoing (DCE) which is a URL to which you can connect to send logs from various sources. It includes code to create the AAD Application and configure all the correct least privledge permissions.

Currently the script does not create a table to insert the data into.

## Send-SampleData.sp1
This script uses an appid/secret to connect to the DCE and send data in JSON format into a specific table.

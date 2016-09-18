# DevConfig is a hash table containing two entries: AllNodes and NoneNodeData.
# The value of each key is an array.
# Each array contains a series of hash tables.

$DevConfig = @{
    AllNodes =
    @(
        @{ NodeName='*';PatchCountMax=10;ResourceName="WebServerConfig"}, # These are things which will apply to all the nodes
        @{ NodeName='VM1';Role="webserver"},
        @{ NodeName='VM2';Role="sqlserver"}
     );
    NoneNodeData =
    @{ LogLocation='c:\temp'}
 }

 # In the real world you would have a separate config datastructure for each environment. e.g.
 # $StageConfig = @ { ... }
 # $LiveConfig = @ { ... }

 Configuration MyConfiguration
 {
    Import-DscResource -ModuleName PSDesiredStateConfiguration

    node $AllNodes.Where{$_.Role -eq 'webserver'}.NodeName
    {
        WindowsFeature $Node.ResourceName
        {
            Name = "web-server"
            Ensure  = "Present"
            LogPath = $ConfigurationData.NoneNodeData.LogLocation;
        }
    }
 }

 MyConfiguration -ConfigurationData $DevConfig -OutputPath c:\temp\configdataexamples
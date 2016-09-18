Configuration WebThing{
Import-DscResource –ModuleName 'PSDesiredStateConfiguration'
    Node ClientConfig {
        WindowsFeature WebServerBlah
        {
            Name = "Web-Server"
            Ensure =  "Present"
        }
    }
}

WebThing -OutputPath C:\temp\configs

Publish-DSCModuleAndMof -Source C:\temp\configs -Force
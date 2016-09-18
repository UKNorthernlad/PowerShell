#iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
# choco install PowerShell
# restart-computer

Import-Certificate -FilePath C:\temp\publicHTTPsCert.cer -CertStoreLocation Cert:\LocalMachine\root


# The lack of the ConfigurationID property in the metaconfiguration below implicitly means that pull server is supporting the V2 version of the pull server protocol.
# This means the client machine needs to make an initial registration with the PullServer.
# Conversely, the presence of a ConfigurationID property means that the V1 version of the pull server protocol is used and there is no registration processing required.

# In a PUSH scenario, a bug exists in the current WMF5.0 release that makes it necessary to define a ConfigurationID property in the metaconfiguration file for
# nodes that have never registered with a pull server. This will force the V1 Pull Server protocol and avoid registration failure messages.

[DSCLocalConfigurationManager()]
configuration PullClientConfigID
{
    Node localhost
    {
        Settings
        {
            RefreshMode          = 'Pull'
            RefreshFrequencyMins = 30 
            RebootNodeIfNeeded   = $true
        }

        ConfigurationRepositoryWeb CONTOSO-PullSrv
        {
            ServerURL          = 'https://pullserver:8080/PSDSCPullServer.svc'
            RegistrationKey    = '64764c28-2bc6-48f5-9819-7eb56bdf7f2e'
            ConfigurationNames = @('ClientConfig') # you can all this what ever you want, e.g. webserver, mycustomconfig etc.
        }   
        
        # The ReportServerWeb section allows reporting data to be sent to the pull server. 
        ReportServerWeb CONTOSO-PullSrv
        {
            ServerURL       = 'https://pullserver:8080/PSDSCPullServer.svc'
            RegistrationKey = '64764c28-2bc6-48f5-9819-7eb56bdf7f2e'
        }
    }
}

mkdir c:\temp -EA SilentlyContinue
PullClientConfigID -OutputPath c:\temp
Set-DSCLocalConfigurationManager -Path c:\temp –Verbose

Get-DscLocalConfigurationManager  # show settings for how the LCM is configured on the local machine.

# Update-DscConfiguration -verbose  -Wait



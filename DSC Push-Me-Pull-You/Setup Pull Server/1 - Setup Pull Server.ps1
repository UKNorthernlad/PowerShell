### Taken from https://msdn.microsoft.com/en-us/powershell/dsc/pullserver plus some of my own stuff

### Update the machine to WMF5.0 which contains PowerShell 5.0
# iex ((new-object net.webclient).DownloadString('https://chocolatey.org/install.ps1'))
# choco install PowerShell
# restart-computer

### You'll probably want your pull server to be running over HTTPS, for this we'll need a valid certificate.
### Either generate one via your internal PKI or generate a self cert SSL. You'll need to install the public certificate part on the client machines. A pain but it works for dev and test environments.
### You can generate the HTTPS cert via either the IIS admin tools or via the command line using makecert.exe
### Getting makecert.exe is often a pain. You get it installed with either Visual Studio or the Windows SDK. See http://www.virtues.it/2015/08/howto-create-selfsigned-certificates-with-makecert/
### You could also just download the binary form a public location you setup.
### Be sure the change CN=pullserver to the name of your pull server, eg. CN=server01.
makecert -r -pe -n "CN=pullserver" -b 01/01/2000 -e 01/01/2036 -eku 1.3.6.1.5.5.7.3.1 -ss my -sr localMachine -sky exchange -sp "Microsoft RSA SChannel Cryptographic Provider" -sy 12
### Make a note of the generated thumbprint, you'll need it for later.

# Export the public certificate of the cert pair we just created. This will be needed on the client machines.
Export-Certificate -Cert Cert:\LocalMachine\my\B2CBDFE6AA3FE8F3ED41AE959AD597A859B688B8 -FilePath  c:\temp\publicHTTPsCert.cer -type CERT

# Here for reference is the import command you'll need on the client machine.
#Import-Certificate -FilePath C:\temp\publicHTTPsCert.cer -CertStoreLocation Cert:\LocalMachine\root

### Download and install the experimental version of the PSDesiredStateConfiguration module which contains some new DSC resources.
install-module xPSDesiredStateConfiguration 

### The DSC resource will install IIS if it's not already installed however here are are explicitly installing it as it's the only way to also install it's managements tools.
Install-WindowsFeature web-server -IncludeManagementTools

configuration Sample_xDscPullServer
{ 
    param  
    ( 
            [string[]]$NodeName = 'localhost', 

            [ValidateNotNullOrEmpty()] 
            [string] $certificateThumbPrint,

            [Parameter(Mandatory)]
            [ValidateNotNullOrEmpty()]
            [string] $RegistrationKey 
     ) 

    # We need to use DSC resource from both the released and experimental versions of the PSDesiredStateConfiguration module.
    # Explicitly load them so PowerShell doesn't complain.
     Import-DSCResource -ModuleName PSDesiredStateConfiguration 
     Import-DSCResource -ModuleName xPSDesiredStateConfiguration 

     Node $NodeName 
     { 
         WindowsFeature DSCServiceFeature 
         { 
             Ensure = 'Present'
             Name   = 'DSC-Service'             
         } 

         xDscWebService PSDSCPullServer 
         { 
             Ensure                  = 'Present' 
             EndpointName            = 'PSDSCPullServer' 
             Port                    = 8080 
             PhysicalPath            = "$env:SystemDrive\inetpub\PSDSCPullServer" 
             CertificateThumbPrint   = $certificateThumbPrint          
             ModulePath              = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Modules" 
             ConfigurationPath       = "$env:PROGRAMFILES\WindowsPowerShell\DscService\Configuration" 
             State                   = 'Started'
             DependsOn               = '[WindowsFeature]DSCServiceFeature'                         
         } 


         

        File RegistrationKeyFile
        {
            Ensure          = 'Present'
            Type            = 'File'
            DestinationPath = "$env:ProgramFiles\WindowsPowerShell\DscService\RegistrationKeys.txt"
            Contents        = $RegistrationKey
        }
    }
}

mkdir c:\temp -ea SilentlyContinue

### This is a guid which will be used by clients to "authenticate" when they pull their configuration. You generate your own for this.
$key = '64764c28-2bc6-48f5-9819-7eb56bdf7f2e'

### Build the .mof file.
Sample_xDSCPullServer -certificateThumbprint 'B2CBDFE6AA3FE8F3ED41AE959AD597A859B688B8' -RegistrationKey $key -OutputPath c:\temp

# Run the compiled configuration to make the target node a DSC Pull Server
Start-DscConfiguration -Path c:\temp -Wait -Verbose### A script that validates the Pull Server is configured correctly: https://github.com/PowerShell/xPSDesiredStateConfiguration/blob/dev/Examples/PullServerDeploymentVerificationTest/PullServerSetupTests.ps1

###################
###################
###################
###################
###################

# Now create some sample modules and MOFS and see if these can be pulled from a client machine.
# There are instuctions on the naming convention to use and the required checksum files at the bottom of the page at https://msdn.microsoft.com/en-us/powershell/dsc/pullserver

# However you can use the module https://github.com/PowerShell/xPSDesiredStateConfiguration/blob/dev/DSCPullServerSetup/PublishModulesAndMofsToPullServer.psm1 to automate most of this.

# Download the script to c:\temp
import-module c:\temp\PublishModulesAndMofsToPullServer.psm1

#Package modules and mof documents from c:\temp\configs
Publish-DSCModuleAndMof -Source C:\temp\configs -Force







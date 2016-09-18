# Deploy Customised VM image

These scripts where written to automate the process of capturing an image of a previously Syspreped machine. The generalised .vhd file is then available for building new machines.


To use the scripts:

1. Run **Sysprep an Azure VM and copy VHD file.ps1** to capture an image of the Sysprep'ed virtual machine. The generalised .vhd file will be located in the same folder as the .vhd it was generated from.
2. Run **Build Clone.ps1**. This will create a new virtal machine based off the new image via the use of an ARM template. Note you'll need to update the parameters.json file to indicate the location of the generalised .vhd file.

As a bonus (**wow!**) it will even download a .ps1 file from the location named in the **ex0_fileUris** parameter in the parameters.json file to carry out post configuration setup for you. You lucky people.

<!-- LINKS -->
[Blah]: https://xXXXXXXX
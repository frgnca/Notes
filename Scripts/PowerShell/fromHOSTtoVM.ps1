<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  fromHOSTtoVM.ps1
  PowerShell script that transfers a file from localhost to virtual machine
#>

################################################################################
# Set transfert parameters
$VirtualMachineName = "test01"
$fromHOST = "C:\file.txt"
$toVM = "/home/test/"
########################
# Enable VMIntegrationService if it is not already
# ToDo: if Get-VMIntegrationService....
#Enable-VMIntegrationService -Name "guest service interface" -VMName $VirtualMachineName #-Name "Interface de services d’invité"

# Copy file from localhost to virtual machine
Copy-VMFile $VirtualMachineName -SourcePath $fromHOST -DestinationPath $toVM -CreateFullPath -FileSource Host

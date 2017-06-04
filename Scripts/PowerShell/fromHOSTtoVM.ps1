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
# If integration service is not enabled
$VMIntegr = Get-VMIntegrationService -VMName $VirtualMachineName | Where-Object -Property Name -EQ "Interface de services d’invité" | Select-Object Enabled
if($VMIntegr.Enabled -ne "True")
{
    # Enable integration service
    Enable-VMIntegrationService -Name "Interface de services d’invité" -VMName $VirtualMachineName #-Name "guest service interface"
}

# Copy file from localhost to virtual machine
Copy-VMFile $VirtualMachineName -SourcePath $fromHOST -DestinationPath $toVM -CreateFullPath -FileSource Host

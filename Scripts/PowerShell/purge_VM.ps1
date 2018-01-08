<#
  Copyright (c) 2017-2018 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  purge_VM.ps1
  PowerShell script that purges a virtual machine
#>

################################################################################
# Set new virtual machine parameters
$VirtualMachineName = "test1"
$VirtualMachineLocation = "D:\VMs"
########################
# Display VM parameters
Write-Host "

########################

         Name: $VirtualMachineName 
Only continue if the parameters are correct"

# Chance to stop before proceeding
Pause

# If virtual machine exists
$exist = $null
$exist = Get-VM | Where-Object -Property Name -EQ $VirtualMachineName
if($exist -ne $null)
{
    # Display instructions
    Write-Host "
########################

Wait time  1+min (100% when done)"

    # Stop virtual machine
    Stop-VM $VirtualMachineName -Force -TurnOff

    # While virtual machine is not off
    while((Get-VM $VirtualMachineName | Select-Object -Property State).State -ne "Off")
    {
        # Wait for a second
        sleep(1)
    }

    # Delete virtual machine from Hyper-V
    Remove-VM $VirtualMachineName -Force
}

# Delete virtual machine folder
$exist = $null
$exist = Test-Path "$VirtualMachineLocation\$VirtualMachineName"
if($exist)
{
    Remove-Item -Recurse -Force "$VirtualMachineLocation\$VirtualMachineName"
}

# Display instructions
Write-Host "
########################

Done

########################"

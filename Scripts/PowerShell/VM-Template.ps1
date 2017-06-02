<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  VM-Template.ps1
  PowerShell script that creates, configures, and starts a new Hyper-V virtual
  machine for the initial operating system installation
#>

################################################################################
# Set VM parameters
$VirtualMachineName = "VM-Template"
$VirtualMachineGeneration = 2
$VirtualMachineMemory = 2GB
$VirtualMachineLocation = "C:\VMs\"
$VirtualHardDriveLocation = "C:\VMs\$VirtualMachineName\Virtual Hard Disks\VHD.vhdx"
$VirtualHardDriveSize = 10GB
$InstallationMediaLocation = "C:\image.iso"
$VirtualSwitchName = "vSwitch"
########################
# Create virtual machine
New-VM -Name $VirtualMachineName -MemoryStartupBytes $VirtualMachineMemory -Generation $VirtualMachineGeneration -NewVHDPath $VirtualHardDriveLocation -NewVHDSizeBytes $VirtualHardDriveSize -Path $VirtualMachineLocation -SwitchName $VirtualSwitchName

# Add DVD drive with installation media to virtual machine
Add-VMDvdDrive -VMName $VirtualMachineName -ControllerNumber 0 -ControllerLocation 1 -Path $InstallationMediaLocation

# Set virtual machine to boot from DVD drive
$DVDDrive = Get-VMDvdDrive -VMName $VirtualMachineName
Set-VMFirmware -VMName $VirtualMachineName -FirstBootDevice $DVDDrive

# Set virtual machine to disable SecureBoot
Set-VMFirmware -VMName $VirtualMachineName -EnableSecureBoot Off

# Start virtual machine
Start-VM -Name $VirtualMachineName

# Connect to virtual machine video console
.\vmconnect.exe localhost $VirtualMachineName

# Pause to performe OS base install and config
Pause
Write-Host "Did you do everything in ""Install Ubuntu Server 16.04.02 on Hyper-V VM.txt""?"
Pause

# Export virtual machine
Export-VM -Name $VirtualMachineName -Path D:\

# Remove virtual machine
Remove-VM $VirtualMachineName

<#
Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
GNU Affero General Public License v3.0

This file is a PowerShell script that creates, configures, and starts a new 
Hyper-V virtual machine for the initial operating system installation
#>

################################################################################
# Set VM parameters
$VirtualMachineName = "VM-Name"
$VirtualMachineGeneration = 2
$VirtualMachineMemory = 2GB
$VirtualMachineLocation = "C:\VMs\$VirtualMachineName"
$VirtualHardDriveLocation = "C:\VMs\$VirtualMachineName\VHD.vhdx"
$VirtualHardDriveSize = 10GB
$VirtualSwitchName = "vSwitch"
$InstallationMediaLocation = "C:\image.iso"
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

# Set virtual machine start action (autostart)
Set-VM -Name $VirtualMachineName -AutomaticStartAction Start

# Set virtual machine stop action (autosave)
Set-VM -Name $VirtualMachineName -AutomaticStopAction Save

# Start virtual machine
Start-VM -Name $VirtualMachineName

# Connect to virtual machine video console
.\vmconnect.exe localhost $VirtualMachineName

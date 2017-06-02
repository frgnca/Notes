<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  cloneTemplate.ps1
  PowerShell script that imports and starts a VM from a template
#>

################################################################################
# Set new virtual machine parameters
$VirtualMachineName = "test01"
$VirtualMachineMemory = 2GB
$VirtualHardDriveSize = 10GB #10GB+
########################
# Set internal variables
$VirtualSwitchName = "vSwitch"
$VirtualMachineGeneration = 2
$VirtualMachineFolder = "C:\VMs\"+$VirtualMachineName
$SnapshotFolder = $VirtualMachineFolder+"\Snapshots"
$VHDFolder = $VirtualMachineFolder+"\Virtual Hard Disks"
$TemplateConfig = "C:\VM-Template\Virtual Machines\FB151D6C-025E-4C96-9FDD-55DA5D04757E.vmcx"

# Import virtual machine template
Import-VM -Path $TemplateConfig -Copy -GenerateNewId -SmartPagingFilePath $VirtualMachineFolder -SnapshotFilePath $SnapshotFolder -VhdDestinationPath $VHDFolder -VirtualMachinePath $VirtualMachineFolder

# Rename virtual machine
Rename-VM -Name "VM-Template" -NewName $VirtualMachineName

# Connect virtual machine to network
Connect-VMNetworkAdapter -VMName $VirtualMachineName -SwitchName $VirtualSwitchName

# Resize VHD
Resize-VHD -Path $VHDFolder"\VHD.vhdx" -SizeBytes $VirtualHardDriveSize

# Set virtual machine to boot from virtual hard drive
$VHD = Get-VMHardDiskDrive -VMName $VirtualMachineName
Set-VMFirmware -VMName $VirtualMachineName -FirstBootDevice $VHD

# Change virtual machine memory
Set-VMMemory $VirtualMachineName -StartupBytes $VirtualMachineMemory

# Set virtual machine to disable SecureBoot
Set-VMFirmware -VMName $VirtualMachineName -EnableSecureBoot Off

# Set virtual machine start action (autostart)
Set-VM -Name $VirtualMachineName -AutomaticStartAction Start

# Set virtual machine stop action (autosave)
Set-VM -Name $VirtualMachineName -AutomaticStopAction Save

# Start virtual machine
Start-VM -Name $VirtualMachineName

# Pause to login, execute setupTemplate.sh, and wait for reboot
Pause
Write-Host "Did you run ""sudo ./setupTemplate.sh""?"
Pause
Write-Host "Did you wait for reboot to complete?"
Pause

# Create snapshot "base"
Get-VM -Name $VirtualMachineName | Checkpoint-VM -SnapshotName "base"

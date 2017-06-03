<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  createVMTemplate.ps1
  PowerShell script that creates, configures, and starts a new Hyper-V virtual
  machine for the initial operating system installation


  Requirements:
  PuTTY
#>

################################################################################
# Set VM parameters
$VirtualMachineName = "VM-Template"
$VirtualMachineGeneration = 2
$VirtualMachineMemory = 2GB
$VirtualMachineLocation = "D:\VMs\"
$VirtualHardDriveLocation = "D:\VMs\$VirtualMachineName\Virtual Hard Disks\VHD.vhdx"
$VirtualHardDriveSize = 10GB
$InstallationMediaLocation = "D:\media\Other\ubuntu-16.04.2-server-amd64.iso"
$VirtualSwitchName = "vSwitch"
########################
# Create virtual machine
New-VM -Name $VirtualMachineName -MemoryStartupBytes $VirtualMachineMemory -Generation $VirtualMachineGeneration -NewVHDPath $VirtualHardDriveLocation -NewVHDSizeBytes $VirtualHardDriveSize -Path $VirtualMachineLocation -SwitchName $VirtualSwitchName > $null

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
vmconnect.exe localhost $VirtualMachineName

# Display instructions
# ToDo: Download and/or open "Install Ubuntu Server 16.04.02 on Hyper-V VM.txt"
Write-Host "########################"
Write-Host ""
Write-Host "See ""Install Ubuntu Server 16.04.02 on Hyper-V VM.txt"""

# Get temporary IP address
# ToDo: Possible to get IP from VM?
$tempIP = Read-Host -Prompt "Temporary IP address"

# While virtual machine does not respond to ping
while(-Not(Test-Connection $tempIP -Count 1 -Quiet))
{
    # Display instructions
    Write-Host "$tempIP unreachable"
    
    # Get temporary IP address
    $tempIP = Read-Host -Prompt "Temporary IP address"
}

# Open ssh session to temporary IP of virtual machine with PuTTY
cd "C:\Program Files\PuTTY"
.\putty.exe -ssh user@$tempIP -pw "password"

# Display instructions 1 of 5
Write-Host ""
Write-Host "Paste in ssh 1/5 (  1%)"
$command = "sudo ufw allow ssh > null && sudo ufw allow 137 > null && sudo ufw allow 138 > null && sudo ufw allow 139 > null && sudo ufw allow 445 > null && sudo ufw --force enable > null && sudo sed -i ""s#iface eth0 inet dhcp#iface eth0 inet static#"" /etc/network/interfaces > null && echo -e ""  address 192.168.1.100\n  netmask 255.255.255.0\n  gateway 192.168.1.1\n  dns-nameservers 8.8.8.8 8.8.4.4"" | sudo tee -a /etc/network/interfaces > null && echo -e ""[root]\n   comment = read only\n   path = /\n   browsable = yes\n   read only = yes\n   guest ok = yes"" | sudo tee -a /etc/samba/smb.conf > null"
$command | clip
Write-Host $command
Write-Host ""
Write-Host "[sudo] password for user:password"
Write-Host ""
Pause

# Display instructions 2 of 5
Write-Host ""
Write-Host "Paste in ssh 2/5 (  75%)"
$command = "sudo apt-get update > null && sudo apt-get -y upgrade > null"
$command | clip
Write-Host $command
Write-Host ""
Pause

# Display instructions 3 of 5
Write-Host ""
Write-Host "Paste in ssh 3/5 (  90%)"
$command = "sudo apt-get -y install --install-recommends linux-virtual-lts-xenial > null"
$command | clip
Write-Host $command
Write-Host ""
Pause

# Display instructions 4 of 5
Write-Host ""
Write-Host "Paste in ssh 4/5 ( 99%)"
$command = "sudo apt-get -y install --install-recommends linux-tools-virtual-lts-xenial linux-cloud-tools-virtual-lts-xenial > null"
$command | clip
Write-Host $command
Write-Host ""
Pause

# Display instructions 5 of 5
Write-Host ""
Write-Host "Paste in ssh 5/5 (100%)"
$command = "sudo shutdown now"
$command | clip
Write-Host $command
Write-Host ""
Write-Host "Then wait"
Write-Host "ssh session will close"

# While virtual machine is not off
while((Get-VM $VirtualMachineName).State -ne "Off")
{
    # Wait 1 second
    sleep(1)
}

# Display instructions
Write-Host ""
Write-Host "Wait (template virtual machine being exported)"

# Export virtual machine
Export-VM -Name $VirtualMachineName -Path D:\

# Display instructions
Write-Host ""
Write-Host "Done"
Write-Host ""

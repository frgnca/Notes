<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  create_templateVM.ps1
  PowerShell script that creates, configures, and exports a template Hyper-V VM


  Requirements:
  PuTTY http://www.putty.org/
#>

################################################################################
# Set template virtual machine parameters
$VirtualMachineName = "_template"
$VirtualHardDriveSize = 10GB
$VirtualMachineMemory = 2GB
$VirtualSwitchName = "vSwitch"
$VirtualMachineLocation = "D:\VMs"
$InstallationMediaLocation = "D:\media\ubuntu-16.04.2-server-amd64.iso"
$exportPath = "D:\media\!Documents\VMs"
########################
# Set internal variables
$VirtualMachineGeneration = 2
$VirtualHardDriveLocation = "$VirtualMachineLocation\$VirtualMachineName\Virtual Hard Disks\VHD.vhdx"
$displayRAMsizeGB = $VirtualMachineMemory / 1024 /1024 / 1024
$displayVHDsizeGB = $VirtualHardDriveSize / 1024 /1024 / 1024

# Display VM parameters
Write-Host "

########################

  VM Name: $VirtualMachineName
  VM VHD:   $displayVHDsizeGB GB
  VM RAM:    $displayRAMsizeGB GB
Only continue if the parameters are correct
#  -> just press Enter
## -> do something, then press Enter"

# Chance to stop before proceeding
Pause

# Display instructions
Write-Host "
########################

Wait time  1 min (   1% when done)
localhost console will open"

# Create virtual machine
New-VM -Name $VirtualMachineName -MemoryStartupBytes $VirtualMachineMemory -Generation $VirtualMachineGeneration -NewVHDPath $VirtualHardDriveLocation -NewVHDSizeBytes $VirtualHardDriveSize -Path $VirtualMachineLocation -SwitchName $VirtualSwitchName > $null

# Add DVD drive with installation media to virtual machine
Add-VMDvdDrive -VMName $VirtualMachineName -ControllerNumber 0 -ControllerLocation 1 -Path $InstallationMediaLocation

# Set virtual machine to boot from DVD drive
$DVDDrive = Get-VMDvdDrive -VMName $VirtualMachineName
Set-VMFirmware -VMName $VirtualMachineName -FirstBootDevice $DVDDrive

# Set virtual machine to disable SecureBoot
Set-VMFirmware -VMName $VirtualMachineName -EnableSecureBoot Off

# Create a pre-install snapshot
Checkpoint-VM -VMName $VirtualMachineName -SnapshotName "pre-install" > $null

# Start virtual machine
Start-VM -Name $VirtualMachineName > $null

# Display ubuntu installation instructions
Write-Host '
########################

  Installation
  GNU GRUB
#  <Install Ubuntu Server>
  Select a language
#  <English>
  Select your location
## <Canada>
  Configure the keyboard
  Detect keyboard layout:
#  <No>
  Country of origin for the keyboard:
## <French (Canada)>
  Keyboard layout:
#  <French (Canada)>

Wait time  1 min (   3% when done)

  Hostname:
#  "ubuntu"
  Set up users and passwords
  Full name for the new user:
#  ""
  Username for your account:
## "user"
  Choose a password for the new user:
## "password"
  Re-enter password to verify:
## "password"
  Encrypt your home directory?
#  <No>
  Configure the clock
  Is this time zone correct?
## <No>
  Select your time zone:
## <Eastern>
  Partition disks
  Partitioning method:
#  <Guided - use entire disk and set up LVM>
  Select disk to partition:
#  <SCSI1 (0,0,0) (sda) - 10.7 GB Msft Virtual Disk>
  Write the changes to disks and configure LVM?
## <Yes>
  Amount of volume group to use for guided partitioning:
#  "9.7 GB"
  Force UEFI installation?
## <Yes>
  Finish partitioning and write changes to disk
  Write the changes to disks?
## <Yes>

Wait time  5 min (  11% when done)

  Configure the package manager
  HTTP proxy information (blank for none):
#  ""

Wait time  1 min (  12% when done)

  Configure tasksel
  How do you want to manage upgrades on this system?
## <Install security updates automatically>
  Software selection
  Choose software to install:
## <Samba file server> (select with spacebar)
   <standard system utilities>
## <openSSH server> (select with spacebar)

Wait time 25+min (  51% when done)

  Finish the installation
#  <Continue>'

# Connect to virtual machine video console
vmconnect.exe localhost $VirtualMachineName

# While tickcount of virtual machine keeps going up (reboots too quickly, cannot catch "Off" state)
$previousTickcount = (Get-VM -Name $VirtualMachineName).Uptime.Ticks
while((Get-VM -Name $VirtualMachineName).Uptime.Ticks -gt $previousTickcount)
{
    # Update tickcount
    $previousTickcount = (Get-VM -Name $VirtualMachineName).Uptime.Ticks
}

# Make sure virtual machine stays stopped
Stop-VM $VirtualMachineName -Force > $null

# Display instructions
Write-Host '
########################

Wait time  1 min (  52% when done)

  Login with localhost console (user:password)
## "user"
## "password"
  Find IP address (192.168.1.???)
## "ifconfig"
##Type the IP address bellow'

# While virtual machine is not off
while((Get-VM -Name $VirtualMachineName).State -ne "Off")
{
    # Wait a second
    sleep(1)
}

# Create a post-install snapshot
Checkpoint-VM -VMName $VirtualMachineName -SnapshotName "post-install" > $null

# Start virtual machine
Start-VM $VirtualMachineName > $null

# Get temporary IP address
$tempIP = Read-Host -Prompt "Temporary IP address"

# While virtual machine does not respond to ping
while(-Not(Test-Connection $tempIP -Count 1 -Quiet))
{
    # Display instructions
    Write-Host "$tempIP unreachable"
    
    # Get temporary IP address
    $tempIP = Read-Host -Prompt "Temporary IP address"
}

# ToDo: Close localhost console
# ToDo: wget a script that does the following instead of pasting commands

# Display instructions 1 of 5
$command = "sudo ufw allow ssh > /dev/null 2>&1 && sudo ufw allow 137 > /dev/null 2>&1 && sudo ufw allow 138 > /dev/null 2>&1 && sudo ufw allow 139 > /dev/null 2>&1 && sudo ufw allow 445 > /dev/null 2>&1 && sudo ufw --force enable > /dev/null 2>&1 && sudo sed -i ""s#iface eth0 inet dhcp#iface eth0 inet static#"" /etc/network/interfaces > /dev/null 2>&1 && echo -e ""  address 192.168.1.100\n  netmask 255.255.255.0\n  gateway 192.168.1.1\n  dns-nameservers 8.8.8.8 8.8.4.4"" | sudo tee -a /etc/network/interfaces > /dev/null 2>&1 && echo -e ""[root]\n   comment = read only\n   path = /\n   browsable = yes\n   read only = yes\n   guest ok = yes"" | sudo tee -a /etc/samba/smb.conf > /dev/null 2>&1"
$command | clip
Write-Host '
########################

  Paste in ssh 1/5
## "'$command'"'
Write-Host '## "password"'

# Open ssh session to temporary IP of virtual machine with PuTTY with user:password
cd "C:\Program Files\PuTTY"
.\putty.exe -ssh user@$tempIP -pw "password"

# Wait for user to be ready to continue
Pause

# Display instructions 2 of 5
$command = "sudo apt-get update > /dev/null 2>&1 && sudo apt-get -y upgrade > /dev/null 2>&1"
$command | clip
Write-Host '
########################

  Paste in ssh 2/5
## "'$command'"'
Write-Host "
Wait time 15+min (  75% when done)"

# Wait for user to be ready to continue
Pause

# Display instructions 3 of 5
$command = "sudo apt-get -y install --install-recommends linux-virtual-lts-xenial > /dev/null 2>&1"
$command | clip
Write-Host '
########################

  Paste in ssh 3/5
## "'$command'"'
Write-Host "
Wait time  5 min (  83% when done)"

# Wait for user to be ready to continue
Pause

# Display instructions 4 of 5
$command = "sudo apt-get -y install --install-recommends linux-tools-virtual-lts-xenial linux-cloud-tools-virtual-lts-xenial > /dev/null 2>&1"
$command | clip
Write-Host '
########################

##Paste in ssh 4/5
## "'$command'"'
Write-Host "
Wait time  1 min ( 85% when done)"

# Wait for user to be ready to continue
Pause

# Display instructions 5 of 5
$command = "sudo shutdown now"
$command | clip
Write-Host '
########################

##Paste in ssh 5/5
## "'$command'"'

Write-Host "
Wait time 10 min (100% when done)
ssh session will close"

# While virtual machine is not off
while((Get-VM $VirtualMachineName).State -ne "Off")
{
    # Wait 1 second
    sleep(1)
}

# Create a base snapshot
Checkpoint-VM -VMName $VirtualMachineName -SnapshotName "template" > $null

# Export virtual machine
Export-VM -Name $VirtualMachineName -Path $exportPath

# Remove virtual machine template from Hyper-V
Remove-VM $VirtualMachineName -Force

# Delete virtual machine folder
Remove-Item -Recurse -Force "$VirtualMachineLocation\$VirtualMachineName"

# Display instructions
Write-Host "
########################

Done

########################"

<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  cloneVMTemplate.ps1
  PowerShell script that imports and starts a VM from an exported template VM
  
  
  Requirements:
  PuTTY
#>

################################################################################
# Set new virtual machine parameters
$VirtualMachineName = "test1"
$VirtualMachineUser = "test"
$VirtualMachineIP = "192.168.1.31"
$VirtualMachineMemory = 2GB #2GB+
$VirtualHardDriveSize = 10GB #10GB+
$startAction = "Nothing" #[Nothing, Start, StartIfRunning]
########################
# Set internal variables
$VirtualSwitchName = "vSwitch"
$VirtualMachineGeneration = 2
$VirtualMachineFolder = "D:\VMs\"+$VirtualMachineName
$SnapshotFolder = $VirtualMachineFolder+"\Snapshots"
$VHDFolder = $VirtualMachineFolder+"\Virtual Hard Disks"
$TemplateConfig = "D:\VM-Template\Virtual Machines\EF055542-D1E1-4FC2-B77F-6F2D769F58AE.vmcx"

# Function to write unix style files by <https://picuspickings.blogspot.ca/2014/04/out-unix-function-to-output-unix-text_17.html>
function Out-Unix
{
    param ([string] $Path)

    begin 
    {
        $streamWriter = New-Object System.IO.StreamWriter("$Path", $false)
    }
    
    process
    {
        $streamWriter.Write(($_ | Out-String).Replace("`r`n","`n"))
    }
    end
    {
        $streamWriter.Flush()
        $streamWriter.Close()
    }
}

# ToDo: Check parameters validity, duplicate host/vm name, IP address, etc.

# Display instructions
Write-Host "########################"
Write-Host ""
Write-Host "Wait (new virtual machine being created from template)"
Write-Host ""

# Copy setupTemplate.sh.old to setupTemplate.sh
$fileContent = Get-Content "D:\Documents\bash\setupTemplate.sh.old"
$setupTemplate = "D:\Documents\bash\setupTemplate.sh"
$fileContent | Out-Unix -Path $setupTemplate

# Find and replace line containing "newHostname=" with $VirtualMachineName
$i = -1
$find = "newHostname="
$replace = "newHostname=""$VirtualMachineName"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $setupTemplate } }

# Find and replace line containing "newUser=" with $VirtualMachineUser
$i = -1
$find = "newUser="
$replace = "newUser=""$VirtualMachineUser"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $setupTemplate } }

# Find and replace line containing "newIP=" with $VirtualMachineIP
$i = -1
$find = "newIP="
$replace = "newIP=""$VirtualMachineIP"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $setupTemplate } }

# Import virtual machine template
Import-VM -Path $TemplateConfig -Copy -GenerateNewId -SmartPagingFilePath $VirtualMachineFolder -SnapshotFilePath $SnapshotFolder -VhdDestinationPath $VHDFolder -VirtualMachinePath $VirtualMachineFolder > $null

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

# Set virtual machine start action
Set-VM -Name $VirtualMachineName -AutomaticStartAction $startAction

# Set virtual machine stop action (autosave)
Set-VM -Name $VirtualMachineName -AutomaticStopAction Save

# If integration service is not enabled
$VMIntegr = Get-VMIntegrationService -VMName $VirtualMachineName | Where-Object -Property Name -EQ "Interface de services d’invité" | Select-Object Enabled
if($VMIntegr.Enabled -ne "True")
{
    # Enable integration service
    Enable-VMIntegrationService -Name "Interface de services d’invité" -VMName $VirtualMachineName #-Name "guest service interface"
}

# Start virtual machine
Start-VM $VirtualMachineName

# While virtual machine does not respond to ping
while(-Not(Test-Connection "192.168.1.100" -Count 1 -Quiet))
{
    # Do nothing, try again
}

# Wait 5 seconds after virtual machine starts responding to ping
# ToDo: find something else more acceptable
sleep(5)

# Copy setupTemplate.sh from localhost to virtual machine
$toVM = "/home/user/"
Copy-VMFile $VirtualMachineName -SourcePath $setupTemplate -DestinationPath $toVM -CreateFullPath -FileSource Host -Force

# Copy .bash_profile from localhost to virtual machine
$bashProfile = "D:\Documents\bash\.bash_profile"
$scriptCall = "sudo ~/./setupTemplate.sh"
$scriptCall | Out-Unix -Path $bashProfile
$toVM = "/home/user/"
Copy-VMFile $VirtualMachineName -SourcePath $bashProfile -DestinationPath $toVM -CreateFullPath -FileSource Host -Force

# Open ssh session to template vm with PuTTY
cd "C:\Program Files\PuTTY"
.\putty.exe -ssh user@192.168.1.100 -pw "password"

# Display instructions
Write-Host "########################"
Write-Host ""
Write-Host "Type ""password"""
Write-Host "Invent a new password"
Write-Host "Retype your newly invented password"
Write-Host ""
Write-Host "Then wait (updates being installed)"
Write-Host "ssh session will close"
Write-Host ""

# While virtual machine is not off
while((Get-VM $VirtualMachineName | Select-Object -Property State).State -ne "Off")
{
    # Wait for a second
    sleep(1)
}

# Display instructions
Write-Host "########################"
Write-Host ""
Write-Host "Wait (""base"" checkpoint being created)"

# Create snapshot "base"
Get-VM -Name $VirtualMachineName | Checkpoint-VM -SnapshotName "base"

# Display instructions
Write-Host "Wait (virtual machine starting)"

# Start virtual machine
Start-VM $VirtualMachineName

# While virtual machine does not respond to ping
while(-Not(Test-Connection $VirtualMachineIP -Count 1 -Quiet))
{
    # Do nothing, try again
}

# Wait 5 seconds after virtual machine starts responding to ping
# ToDo: find something else more acceptable
sleep(5)

# Display instructions
Write-Host "Done"

# Open ssh session to newly configured virtual machine with PuTTY
cd "C:\Program Files\PuTTY"
.\putty.exe -ssh $VirtualMachineUser@$VirtualMachineIP

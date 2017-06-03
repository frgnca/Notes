<#
  Copyright (c) 2017 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  cloneTemplate.ps1
  PowerShell script that imports and starts a VM from an exported template VM
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
$VirtualMachineFolder = "C:\VMs\"+$VirtualMachineName
$SnapshotFolder = $VirtualMachineFolder+"\Snapshots"
$VHDFolder = $VirtualMachineFolder+"\Virtual Hard Disks"
$TemplateConfig = "C:\VM-Template\Virtual Machines\FB151D6C-025E-4C96-9FDD-55DA5D04757E.vmcx"

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

# Display instructions
Write-Host "########################"
Write-Host ""
Write-Host "Wait (new virtual machine being created from template)"
Write-Host ""

# Get setupTemplate.sh file content
$fromHOST = "D:\Documents\bash\setupTemplate.sh"
$fileContent = Get-Content $fromHOST

# Find and replace line containing "newHostname=" with $VirtualMachineName
$i = -1
$find = "newHostname="
$replace = "newHostname=""$VirtualMachineName"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $fromHOST } }

# Find and replace line containing "newUser=" with $VirtualMachineUser
$i = -1
$find = "newUser="
$replace = "newUser=""$VirtualMachineUser"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $fromHOST } }

# Find and replace line containing "newIP=" with $VirtualMachineIP
$i = -1
$find = "newIP="
$replace = "newIP=""$VirtualMachineIP"""
$fileContent | ForEach-Object {$i++; if($_ -match $find){ $fileContent[$i] = $replace; $fileContent | Out-Unix -Path $fromHOST } }

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

# Copy file from localhost to virtual machine
$fromHOST = "D:\Documents\bash\setupTemplate.sh"
$toVM = "/home/user/"
Copy-VMFile $VirtualMachineName -SourcePath $fromHOST -DestinationPath $toVM -CreateFullPath -FileSource Host -Force

# Display instructions
Write-Host "########################"
Write-Host ""
Write-Host "ssh into 192.168.1.100 with user:user and password:password"
Write-Host ""
Write-Host "Type ""sudo ./setupTemplate.sh"""
Write-Host "Type ""password"""
Write-Host "Invent a new password"
Write-Host "Type your newly invented password again"
Write-Host ""
Write-Host "Wait (updates being installed)"
Write-Host "ssh session will close"
Write-Host ""

# While virtual machine is not off
while((Get-VM $VirtualMachineName | Select-Object -Property State).State -ne "Off")
{
    # Wait for a second
    sleep(1)
}

# Display instructions

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

# Display instructions
Write-Host "Login with ssh to $VirtualMachineIP with user:$VirtualMachineUser and the password you created previously"

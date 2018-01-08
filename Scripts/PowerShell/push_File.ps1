<#
  Copyright (c) 2017-2018 Francois Gendron <fg@frgn.ca>
  GNU Affero General Public License v3.0

  push_File.ps1
  PowerShell script that transfers a file from localhost to virtual machine
#>

################################################################################
# Set transfert parameters
$VirtualMachineName = "test2"
$fromHOST = "D:\frgnca\Documents\_fg\VM_setup\minecraft\" # if folder, end name with \
$toVM = "/" # end name with /
########################
# Enable VMIntegrationService if it is not already
# ToDo: if Get-VMIntegrationService....
#Enable-VMIntegrationService -Name "Interface de services d’invité" -VMName $VirtualMachineName #-Name "guest service interface"

# ToDo: foreach calls a function, same as for a single file

# Check if it's a folder or a single file
if($fromHOST.Substring($fromHOST.Length - 1) -eq "\")
{
    # It's a folder

    # For every file including files in subfolders
    Get-ChildItem $fromHOST -Recurse | Where-Object -Property Mode -EQ "-a----" | ForEach-Object {    
        # Get subfolders string, there won't be any is this file is in the base folder
        $subFolder = $_.FullName.Substring($fromHOST.Length, $_.FullName.Substring($fromHOST.Length).Length - $_.Name.Length)

        # Replace \ to / in $subFolder
        $subFolder = $subFolder.Replace("\", "/")

        $destinationPath = $toVM + $subFolder

        # Copy file from localhost to virtual machine
        Copy-VMFile $VirtualMachineName -SourcePath $_.FullName -DestinationPath $destinationPath -CreateFullPath -FileSource Host -Force

        # Display file copied
        $outFile = $destinationPath + $_.Name
        Write-Host $outFile
    }
}
else
{
    # It's a single file
    
    # Copy file from localhost to virtual machine
    Copy-VMFile $VirtualMachineName -SourcePath $fromHOST -DestinationPath $toVM -CreateFullPath -FileSource Host -Force

    # Display file copied
    Write-Host $_.FullName
}
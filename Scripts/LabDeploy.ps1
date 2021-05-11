try {
    $tgelab = Import-Lab -Name TGELAB
}
catch { # Lab n'existe pas
    New-LabDefinition -Name TGELAB -DefaultVirtualizationEngine HyperV
}

# Récupération des définitions DSC
Get-ChildItem -Path "../MOF/*" -Include *-DEV.mof | ForEach-Object {
    try {
        Get-LabVM -ComputerName $_.Name
    } catch {
        Add-LabMachineDefinition -Name $_.Name -OperatingSystem 'Windows Server 2019 Standard'
    }
}

try {
    Get-LabVM -ComputerName PUSH01-DEV
}
catch {
    Add-LabDiskDefinition -Name PUSH-HDD -DiskSizeInGb 30
    Add-LabMachineDefinition -Name "PUSH01-DEV" -OperatingSystem 'Windows Server 2019 Standard' -Roles FileServer -DiskName PUSH-HDD
}
Install-Lab

#Transfert des fichiers DSC vers les VMs
ForEach ($vm in Get-LabVM) {
    Copy-LabFileItem -Path "\\LAB01\DSC\MOF\$vm.Name.mof" -ComputerName $vm.Name -DestinationFolder "C:\DSC"
}

Invoke-LabCommand -ComputerName PUSH01-DEV -ScriptBlock {
    New-Item -Path "C:\MODULES" -ItemType Directory
    New-SmbShare -Name MODULES -Path "C:\MODULES" -ReadAccess Everyone
}
Copy-LabFileItem -Path "\\LAB01\DSC\CModules\*" -ComputerName PUSH01-DEV -DestinationFolder "C:\MODULES"
Invoke-LabCommand -ComputerName DC01-DEV -ScriptBlock { Start-DscConfiguration -Path "C:\DSC"}
Show-LabDeploymentSummary



Write-Host "Construction ou mise à jour de TGELAB"


try {
    Write-Host "Tentative d'importation du laboratoire"
    $tgelab = Import-Lab -Name TGELAB
}
catch { # Lab n'existe pas
    Write-Host "Laboration n'existant pas, création du laboratoire TGELAB"
    New-LabDefinition -Name TGELAB -DefaultVirtualizationEngine HyperV
    Add-LabVirtualNetworkDefinition -Name 'LAN' -AddressSpace 192.168.111.0/24
}

Write-Host "Ajout des VMs au laboratoire"
# Récupération des définitions DSC
Get-ChildItem -Path "C:\DSC\MOF\*" -Include *-DEV.mof | ForEach-Object {
    $vmname = $_.BaseName
    Write-Host "Vérification de l'existance de $vmname"
    $vm = Get-LabVM -ComputerName $vmname
    if (-not $vm) {
        Write-Host "$vmname n'existe pas, création en cours..."
        Add-LabMachineDefinition -Name $vmname -OperatingSystem 'Windows Server 2019 Standard' -Network LAN -IpAddress 192.168.111.100
    }
}

Write-Host "Installation du laboratoire en cours"
Install-Lab

Write-Host "Transfert des modules compressés vers chaque VM"
#Transfert des fichiers DSC vers les VMs
ForEach ($vm in Get-LabVM) {
    $vmname = $vm
    Write-Host "Transfert vers $vmname"
    Copy-LabFileItem -Path "C:\DSC\Compressed Modules" -ComputerName $vm -DestinationFolder "C:\DSC\"
    Write-Host "Création du share local pour $vmname"
    Invoke-LabCommand -ComputerName $vm -ScriptBlock {
        New-SmbShare -Name MODULES -Path "C:\DSC\Compressed Modules" -ReadAccess Everyone
    }
    Write-Host "Mise à jour du LCM sur $vmname"
    $c = New-LabCimSession -ComputerName $vm
    Set-DscLocalConfigurationManager -CimSession $c -Path "C:\DSC\Meta Mof" -Verbose
    Start-DscConfiguration -CimSession $c -Path "C:\DSC\MOF" -Wait -Verbose -Force
}




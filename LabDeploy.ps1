New-LabDefinition -Name TGELAB -DefaultVirtualizationEngine HyperV

Add-LabMachineDefinition -Name 'Windows Server 2019 Standard'

Install-Lab

Show-LabDeploymentSummary
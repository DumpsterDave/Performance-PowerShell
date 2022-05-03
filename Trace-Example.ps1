#region setup
Import-Module "$(Get-Location)\PSPerformance.psm1"

$Services = Get-Service
#endregion

#region Initial Trace-Command
$BaselineCode = {
    foreach ($svc in $Services) {
        if ($svc.Status -eq 'Running' -and $Svc.StartupType -eq 'Automatic') {
            Write-Output $svc.Name
        }
    }
}
Trace-Command -Name TypeConversion -ListenerOption Timestamp -Expression $BaselineCode -PSHost
#endregion

#region Trace-Command with Enum Called out
$OptimizedCode = {
    foreach ($svc in $Services) {
        if ($svc.Status -eq [System.ServiceProcess.ServiceControllerStatus]::Running -and $Svc.StartupType -eq [System.ServiceProcess.ServiceStartMode]::Automatic) {
            Write-Output $svc.Name
        }
    }
}
Trace-Command -Name TypeConversion -ListenerOption Timestamp -Expression $OptimizedCode -PSHost
#endregion

#Lets Compare
$Baseline = Test-Performance -Count 10 -ScriptBlock $BaselineCode
$WithEnum = Test-Performance -Count 10 -ScriptBlock $OptimizedCode
Get-Winner -AName 'Baseline' -AValue $Baseline.Median -BName "Enumerated" -BValue $WithEnum.Median
#endregion
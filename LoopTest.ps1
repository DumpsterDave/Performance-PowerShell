Import-Module "$($PSScriptRoot)\PSPerformance.psm1" -Force

$Array2 = New-TestObjectArray 100
$Array3 = New-TestObjectArray 100

ForEach-Object -InputObject $Array3 -MemberName IdUp

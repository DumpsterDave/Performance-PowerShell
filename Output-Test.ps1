Set-Location $PSScriptRoot
Import-Module './PSPerformance.psm1' -Force
$LeftTitle = "Write-Host"
$RightTitle = "Write-Output"

$Left = Test-Performance -Count 10 -ScriptBlock {
    for ($i = 0; $i -lt 1000; $i++) {
        $BGr = Get-Random -Minimum 0 -Maximum 15
        $BGg = Get-Random -Minimum 0 -Maximum 15
        $BGb = Get-Random -Minimum 0 -Maximum 15
        $FGr = Get-Random -Minimum 0 -Maximum 15
        $FGg = Get-Random -Minimum 0 -Maximum 15
        $FGb = Get-Random -Minimum 0 -Maximum 15
        Write-Host "Write-Host" -BackgroundColor $BGr -ForegroundColor $FGr
    }
}

$Right = Test-Performance -Count 10 -ScriptBlock {
    for ($i = 0; $i -lt 1000; $i++) {
        $BGr = Get-Random -Minimum 0 -Maximum 255
        $BGg = Get-Random -Minimum 0 -Maximum 255
        $BGb = Get-Random -Minimum 0 -Maximum 255
        $FGr = Get-Random -Minimum 0 -Maximum 255
        $FGg = Get-Random -Minimum 0 -Maximum 255
        $FGb = Get-Random -Minimum 0 -Maximum 255
        Write-Output "`e[38;2;$($FGr);$($FGg);$($FGb)m`e[48;2;$($BGr);$($BGg);$($BGb)mWrite-Output`e[0m"
    }
}

Get-Winner -AName $LeftTitle -AValue $Left.Median -BName $RightTitle -BValue $Right.Median
Import-Module "$($PSScriptRoot)\PSPerformance.psm1" -Force
[void][Reflection.Assembly]::LoadFile("$($PSScriptRoot)\PoShCSharpExample.dll")
function Get-RandomSquare {
    $r = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
    return ($r * $r)
}
$Iterations = 10
$LeftTitle = "Function"
$RightTitle = "C# Function"

$Left = Test-Performance -Count $Iterations -ScriptBlock {    
    for ($i = 0; $i -lt 1000; $i++) {
        $x = (Get-RandomSquare)
    }
}

$Right = Test-Performance -Count $Iterations -ScriptBlock {    
    for ($i = 0; $i -lt 1000; $i++) {
        $x = ([PoShCSharpExample.PoShCSharp]::GetRandomSquare())
    }
}

Get-Winner -AName $LeftTitle -AValue $Left.Median -BName $RightTitle -BValue $Right.Median

$Left = Test-Performance -Count $Iterations -ScriptBlock {    
    for ($i = 0; $i -lt 1000; $i++) {
        $R = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
        $x = $R * $R
    }
}
$LeftTitle = "Code"
Get-Winner -AName $LeftTitle -AValue $Left.Median -BName $RightTitle -BValue $Right.Median

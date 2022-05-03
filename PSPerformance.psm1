class TestObject {
    [guid]$Id = [guid]::NewGuid()
    [int]$Number
    [string]$Word
    [datetime]$Timestamp

    TestObject() {
        $this.Number = Get-Random
        $this.Timestamp = Get-Date
        $this.Word = $this.CreateRandomWord(32)
    }

    [string]CreateRandomWord([int]$Length) {
        $rWord = ''
        for ($i = 0; $i -lt $Length; $i++) {
            $rWord += [Convert]::ToChar((Get-Random -Minimum 65 -Maximum 128))
        }
        return $rWord
    }
}
function Test-Performance {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateRange(5,50000000)]
        [int]$Count,
        [Parameter(Mandatory=$true,Position=2)]
        [ScriptBlock]$ScriptBlock,
        [Parameter(Mandatory=$false,Position=3)]
        [Object[]]$PassedObj = $null,
        [Parameter(Mandatory=$false)]
        [switch]$SuppressStreams
    )
    $Private:Occurrence = [System.Collections.Generic.List[Double]]::new()
    $Private:Sorted = [System.Collections.Generic.List[Double]]::new()
    $Private:ScriptBlockOutput = [System.Collections.Generic.List[string]]::new()
    $Private:ScriptBlockWarning = [System.Collections.Generic.List[string]]::new()
    $Private:ScriptBlockError = [System.Collections.Generic.List[string]]::new()
    $Private:ScriptBlockInfo = [System.Collections.Generic.List[string]]::new()
    [Double]$Private:Sum = 0
    [Double]$Private:Mean = 0
    [Double]$Private:Median = 0
    [Double]$Private:Minimum = 0
    [Double]$Private:Maximum = 0
    [Double]$Private:Range = 0
    [Double]$Private:Variance = 0
    [Double]$Private:StdDeviation = 0
    $Private:ReturnObject = '' | Select-Object Occurrence,Sorted,Sum,Mean,Median,Minimum,Maximum,Range,Variance,StdDeviation,Output,Information,Warning,Error
 
    #Gather Results
    for ($i = 0; $i -lt $Count; $i++) {
        $Timer = [System.Diagnostics.Stopwatch]::StartNew()
        if ($null -ne $PassedObj) {
            $Private:Output = Invoke-Command -ScriptBlock $ScriptBlock -ArgumentList (,$PassedObj) -InformationVariable iv -ErrorVariable ev -OutVariable ov -WarningVariable wv
        } else {
            $Private:Output = Invoke-Command -ScriptBlock $ScriptBlock -InformationVariable iv -ErrorVariable ev -OutVariable ov -WarningVariable wv
        }
        $Timer.Stop()
        $Private:Result = $Timer.Elapsed
        $Private:Sum += $Private:Result.TotalMilliseconds
        [void]$Private:ScriptBlockOutput.Add($ov)
        [void]$Private:ScriptBlockWarning.Add($wv)
        [void]$Private:ScriptBlockError.Add($ev)
        [void]$Private:ScriptBlockInfo.Add($iv)
        [void]$Private:Occurrence.Add($Private:Result.TotalMilliseconds)
        [void]$Private:Sorted.Add($Private:Result.TotalMilliseconds)
    }
    $Private:ReturnObject.Sum = $Private:Sum
    $Private:ReturnObject.Occurrence = $Private:Occurrence
    if ($SuppressStreams) {
        $Private:ReturnObject.Output = "Suppressed"
        $Private:ReturnObject.Warning = "Suppressed"
        $Private:ReturnObject.Error = "Suppressed"
        $Private:ReturnObject.Information = "Suppressed"
    } else {
        $Private:ReturnObject.Output = $Private:ScriptBlockOutput
        $Private:ReturnObject.Warning = $Private:ScriptBlockWarning
        $Private:ReturnObject.Error = $Private:ScriptBlockError
        $Private:ReturnObject.Information = $Private:ScriptBlockInfo
    }
    
    #Sort
    $Private:Sorted.Sort()
    $Private:ReturnObject.Sorted = $Private:Sorted
 
    #Statistical Calculations
    #Mean (Average)
    $Private:Mean = $Private:Sum / $Count
    $Private:ReturnObject.Mean = $Private:Mean
 
    #Median
    if (($Count % 2) -eq 1) {
        $Private:Median = $Private:Sorted[([Math]::Ceiling($Count / 2))]
    } else {
        $Private:Middle = $Count / 2
        $Private:Median = (($Private:Sorted[$Private:Middle]) + ($Private:Sorted[$Private:Middle + 1])) / 2
    }
    $Private:ReturnObject.Median = $Private:Median
 
    #Minimum
    $Private:Minimum = $Private:Sorted[0]
    $Private:ReturnObject.Minimum = $Private:Minimum
 
    #Maximum
    $Private:Maximum = $Private:Sorted[$Count - 1]
    $Private:ReturnObject.Maximum = $Private:Maximum
 
    #Range
    $Private:Range = $Private:Maximum - $Private:Minimum
    $Private:ReturnObject.Range = $Private:Range
 
    #Variance
    for ($i = 0; $i -lt $Count; $i++) {
        $x = ($Private:Sorted[$i] - $Private:Mean)
        $Private:Variance += ($x * $x)
    }
    $Private:Variance = $Private:Variance / $Count
    $Private:ReturnObject.Variance = $Private:Variance
 
    #Standard Deviation
    $Private:StdDeviation = [Math]::Sqrt($Private:Variance)
    $Private:ReturnObject.StdDeviation = $Private:StdDeviation
     
    return $Private:ReturnObject
}
Function Get-Winner {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]$AName,
        [Parameter(Mandatory=$true,Position=2)]
        [ValidateNotNullOrEmpty()]
        [Double]$AValue,
        [Parameter(Mandatory=$true,Position=3)]
        [ValidateNotNullOrEmpty()]
        [string]$BName,
        [Parameter(Mandatory=$true,Position=4)]
        [ValidateNotNullOrEmpty()]
        [Double]$BValue
    )
    if ($ClearBetweenTests) {
        Clear-Host
    }
 
    $blen = $AName.Length + $BName.Length + 12
    $Border = ''
    for ($i = 0; $i -lt $blen; $i++) {
        $Border += '*'
    }
 
    if ($OutToFile) {
        Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject $Border
        Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject ([string]::Format('**  {0} vs {1}  **', $AName, $BName))
        Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject $Border
    }
    Write-Host $Border -ForegroundColor White
    Write-Host ([string]::Format('**  {0} vs {1}  **', $AName, $BName)) -ForegroundColor White
    Write-Host $Border -ForegroundColor White
 
    if ($AValue -lt $BValue) {
        $Faster = $BValue / $AValue
        if ($Faster -lt 1.05) {
            $Winner = 'Tie'
            $AColor = [ConsoleColor]::White
            $BColor = [ConsoleColor]::White
        } else {
            $Winner = $AName
            $AColor = [ConsoleColor]::Green
            $BColor = [ConsoleColor]::Red
        }
    } elseif ($AValue -gt $BValue) {
        $Faster = $AValue / $BValue
        if ($Faster -lt 1.05) {
            $Winner = 'Tie'
            $AColor = [ConsoleColor]::White
            $BColor = [ConsoleColor]::White
        } else {
            $Winner = $BName
            $AColor = [ConsoleColor]::Red
            $BColor = [ConsoleColor]::Green
        }
    } else {
        $Winner = 'Tie'
        $AColor = [ConsoleColor]::White
        $BColor = [ConsoleColor]::White
        $Faster = 0
    }
     
    $APad = ''
    $BPad = ''
    if ($AName.Length -gt $BName.Length) {
        $LenDiff = $AName.Length - $BName.Length
        for ($i = 0; $i -lt $LenDiff; $i++) {
            $BPad += ' '
        }
    } else {
        $LenDiff = $BName.Length - $AName.Length
        for ($i = 0; $i -lt $LenDiff; $i++) {
            $APad += ' '
        }
    }
 
    $AValue = [Math]::Round($AValue, 3)
    $BValue = [Math]::Round($BValue, 3)
    $Faster = [Math]::Round($Faster, 2)
     
    if ($OutToFile) {
        Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject ([string]::Format('{0}:  {1}{2}ms', $AName, $APad, $AValue))
        Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject ([string]::Format('{0}:  {1}{2}ms', $BName, $BPad, $BValue))
        if ($Winner -eq 'Tie') {
            Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject 'WINNER: Tie`r`n'
        } else {
            Out-File -FilePath $OutFileName -Append -Encoding utf8 -InputObject ([string]::Format('WINNER: {0} {1}x Faster`r`n', $Winner, $Faster))
        }
    }
    Write-Host ([string]::Format('{0}:  {1}{2}ms', $AName, $APad, $AValue)) -ForegroundColor $AColor
    Write-Host ([string]::Format('{0}:  {1}{2}ms', $BName, $BPad, $BValue)) -ForegroundColor $BColor
    if ($Winner -eq 'Tie') {
        Write-Host 'WINNER: Tie' -ForegroundColor Yellow
    } else {
        Write-Host ([string]::Format('WINNER: {0} {1} times Faster', $Winner, $Faster)) -ForegroundColor Yellow
    }
    if ($PauseBetweenTests -eq $true) {
        Pause
    }
}
function New-TestObjectArray {
    Param(
        [Parameter(Mandatory=$true,Position=0)]
        [int]$Size
    )
    $Array = [TestObject[]]::new($Size)
    for ($i = 0; $i -lt $Size; $i++) {
        $insert = [TestObject]::new()
        $Array[$i] = $insert
    }
    return $Array
}

function New-TestObjectList {
    Param (
        [Parameter(Mandatory = $true, Position = 0)]
        [int]$Size
    )
    $List = [System.Collections.Generic.List[TestObject]]::new()
    for ($i = 0; $i -lt $Size; $i++) {
        $insert = [TestObject]::new()
        [void]$List.Add($insert)
    }
    return $List
}

function New-RandomWord {
    Param(
        [Parameter(Mandatory=$true,Position=1)]
        [int]$Length
    )
    $rWord = ''
    for ($i = 0; $i -lt $Length; $i++) {
        $rWord += [Convert]::ToChar((Get-Random -Minimum 65 -Maximum 128))
    }
    return $rWord
}


Export-ModuleMember -Function 'Test-Performance'
Export-ModuleMember -Function 'Get-Winner'
Export-ModuleMember -Function 'New-TestObjectArray'
Export-ModuleMember -Function 'New-TestObjectList'
Export-ModuleMember -Function 'New-RandomWord'
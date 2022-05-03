[CmdletBinding(DefaultParameterSetName="SingleTest")]
Param(
    [Parameter(Mandatory=$true,Position=1,ParameterSetName="SingleTest")]
    [ValidateRange(0,20)]
    [int]$Test,
    [Parameter(Mandatory=$true,Position=1,ParameterSetName="Batch")]
    [switch]$Batch,
    [Parameter(Mandatory=$false,Position=2,ParameterSetName="Batch")]
    [string]$OutFile = "Batch_$($PSVersionTable.PSVersion.ToString())_$($PSVersionTable.PSEdition).csv"
)

Import-Module "$($PSScriptRoot)\PSPerformance.psm1" -Force

if ($Batch) {
    #region Batch
    #region Batch Setup
    if ($PSVersionTable.PSVersion.Major -ge 7) {
        $PSStyle.Progress.View = [System.Management.Automation.ProgressView]::Classic
    }
    $ErrorActionPreference = 'Inquire'
    if ($null -eq $PSScriptRoot) {
        $Path = "$(Get-Location)/TestFiles"
    } else {
        $Path = "$($PSScriptRoot)/TestFiles/"
    }
    if (-not(Test-Path -Path $Path -PathType Container)) {
        [void](New-Item -Path (Split-Path -Path $Path -Parent) -Name "TestFiles" -ItemType Directory)
    }
    Write-Host "Generating Test Files..." -ForegroundColor Magenta -NoNewline
    for($i = 0; $i -lt 10000; $i++) {
        if (-not(Test-Path -Path "$($Path)/$($i).test" -PathType Leaf)) {
            Out-File -FilePath "$($Path)/$($i).test" -Encoding utf8 -InputObject (New-RandomWord -Length 256)
        }
    }
    Write-Host "  DONE"

    if ($OutFile -notmatch ":\\") {
        $OutFile = "$($PSScriptRoot)/$($Outfile)"   #$OutFile is a filename, Prepend our CWD
    }
    #endregion
    Write-Progress -Id 0 -Activity "Running Performance Comparisons" -PercentComplete 0
    $CsvWriter = [System.IO.StreamWriter]::new($OutFile, $false, [System.Text.Encoding]::UTF8)
    $CsvWriter.WriteLine("PowerShell version $($PSVersionTable.PSVersion.ToString()) - $($PSVersionTable.PSEdition)")
    $CsvWriter.WriteLine("Test Name,Count,Sum,Mean,Median,Minimum,Maximum,Range,Variance,Std Deviation,Occurrances")
    $CTest = 0
    $TotalTest = 34

    #region Filter
    $Name = "Filter"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    if ($PROFILE -match '/home/.*') {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path '/etc' -Filter '*.d'
        }
    } else {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path 'C:\Windows\System32' -Filter '*.exe'
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Where-Object 
    $Name = "Where-Object"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    if ($PROFILE -match '/home/.*') {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path '/etc' | Where-Object {$_.Extension -eq '.d'}
        }
    } else {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path 'C:\Windows\System32' | Where-Object {$_.Extension -eq '.exe'}
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")    #endregion
    #endregion

    #region Path Filter
    $Name = "Path Filter"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    if ($PROFILE -match '/home/.*') {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path '/etc/*.exe'
        }
    } else {
        $Result = Test-Performance -Count $Iterations -ScriptBlock {
            $Objs = Get-ChildItem -Path 'C:\Windows\System32\*.exe'
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")    #endregion
    #endregion

    #region For
    $Name = "For"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $ForArray = New-TestObjectArray -Size 10000
    $Result = Test-Performance -Count $Iterations -PassedObj $ForArray -ScriptBlock {
        Param([Object[]]$Obj)
        $len = $Obj.Count
        for ($i = 0; $i -lt $len; $i++) {
            $Obj[$i].Number = Get-Random
        }
    }
    Remove-Variable ForArray
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")    #endregion
    #endregion

    #region ForEach
    $Name = "ForEach"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $ForEachArray = New-TestObjectArray -Size 10000
    $Result = Test-Performance -Count $Iterations -PassedObj $ForEachArray -ScriptBlock {
        Param([Object[]]$Obj)
        foreach ($fe in $Obj) {
            $fe.Number = Get-Random
        }
    }
    Remove-Variable ForEachArray
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")    #endregion
    #endregion

    #region .ForEach
    $Name = ".ForEach"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $DotForEachArray = New-TestObjectArray -Size 10000
    $Result = Test-Performance -Count $Iterations -PassedObj $DotForEachArray -ScriptBlock {
        Param([Object[]]$Obj)
        $Obj.ForEach{
            $_.Number = Get-Random
        }
    }
    Remove-Variable DotForEachArray
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")    #endregion
    #endregion

    #region | ForEach
    $Name = "| ForEach-Object"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $PipeForEachArray = New-TestObjectArray -Size 10000
    $Result = Test-Performance -Count $Iterations -PassedObj $PipeForEachArray -ScriptBlock {
        Param([Object[]]$Obj)
        $Obj | ForEach-Object -Process {
            $_.Number = Get-Random
        }
    }
    Remove-Variable PipeForEachArray
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Array
    $Name = "Array"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Array = @()
        for ($i =0; $i -lt 10000; $i++) {
            $Obj = [TestObject]::new()
            $Array += $Obj
        }
        Remove-Variable Array
    }
    
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region ArrayList
    $Name = "ArrayList"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $ArrayList = [System.Collections.ArrayList]::new()
        for ($i =0; $i -lt 10000; $i++) {
            $Obj = [TestObject]::new()
            [void]$ArrayList.Add($Obj)
        }
        Remove-Variable ArrayList
    }

    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Object List
    $Name = "Object List"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $List = [System.Collections.Generic.List[Object]]::new()
        for ($i =0; $i -lt 10000; $i++) {
            $Obj = [TestObject]::new()
            [void]$List.Add($Obj)
        }
        Remove-Variable List
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region TypeCast List
    $Name = "TypeCast List"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $List = [System.Collections.Generic.List[TestObject]]::new()
        for ($i =0; $i -lt 10000; $i++) {
            $Obj = [TestObject]::new()
            [void]$List.Add($Obj)
        }
        Remove-Variable List
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region -Replace
    $Name = "'-Replace'"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Haystack = "The Quick Brown Fox Jumped Over the Lazy Dog 5 Times"
        $Needle = "\ ([\d]*)\ "
        for ($i = 0; $i -lt 10000; $i++) {
            [void]($Haystack -replace $Needle, " $(Get-Random) ")
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Regex.Replace
    $Name = "Regex.Replace"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Haystack = "The Quick Brown Fox Jumped Over the Lazy Dog 5 Times"
        $Needle = "\ ([\d]*)\ "
        for ($i = 0; $i -lt 10000; $i++) {
            [void]([regex]::Replace($Haystack, $Needle, " $(Get-Random) "))
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Pipes
    $Name = "Pipes"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Obj = Get-ChildItem -Path $Path | Get-FileHash -Algorithm SHA512 | Select-Object Hash
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Long Form
    $Name = "Long Form"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Files = Get-ChildItem -Path $Path
        $Hashes = [System.Collections.Generic.List[Object]]::new()
        foreach ($file in $Files) {
            $Hash = Get-FileHash -Path $file.FullName -Algorithm SHA512
            [void]$Hashes.Add($Hash.Hash)
        }
        $Obj = $Hashes.ToArray()
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region String Builder
    $Name = "String Builder"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $String1 = ""
        $sb = [System.Text.StringBuilder]::new()
        for ($i = 0; $i -lt 10000; $i++) {
            [void]$sb.Append("A")
        }
        $String1 = $sb.ToString()
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region String +=
    $Name = "String +="
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        [string]$String2 = ""
        for ($i = 0; $i -lt 10000; $i++) {
            $String2 += 'B'
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Composite String Formatting
    $Name = "Composite String Formatting"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $String3 = ""
        for ($i = 0; $i -lt 10000; $i++) {
            $a = Get-Random
            $b = Get-Random
            $String3 = [string]::Format("{0} {1}", $a, $b)
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Interpolated String Formatting
    $Name = "Interpolated String Formatting"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $String4 = ""
        for ($i = 0; $i -lt 10000; $i++) {
            $a = Get-Random
            $b = Get-Random
            $String4 = "$($a) $($b)"
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Get-Content
    $Name = "Get-Content"
    $Iterations = 1000
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Stuff = Get-Content -Path "$($PSScriptRoot)/Item1.txt" -Encoding UTF8
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region [System.IO.StreamReader]
    $Name = "[System.IO.StreamReader]"
    $Iterations = 1000
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $StreamReader = [System.IO.StreamReader]::new("$($PSScriptRoot)/Item1.txt", [System.Text.Encoding]::UTF8)
        $More = $StreamReader.ReadToEnd()
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region [void]
    $Name = "[void]"
    $Iterations = 1000
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $vl = [System.Collections.Generic.List[int]]::new()
        for ($i = 0; $i -lt 1000; $i++) {
            [void]$vl.Add((Get-Random))
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region | Out-Null
    $Name = "| Out-Null"
    $Iterations = 1000
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $on = [System.Collections.Generic.List[int]]::new()
        for ($i = 0; $i -lt 1000; $i++) {
            $on.Add((Get-Random)) | Out-Null
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Write-Host
    $Name = "Write-Host"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        for ($i =0; $i -lt 100; $i++) {
            Write-Host "The quick brown fox jumps over the lazy dog"
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Write-Output
    $Name = "Write-Output"
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        for ($i =0; $i -lt 100; $i++) {
            Write-Output "The quick brown fox jumps over the lazy dog"
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region [Console]::WriteLine()
    $Name = "[Console]::WriteLine()"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        for ($i = 0; $i -lt 100; $i++) {
            [Console]::WriteLine("The quick brown fox jumps over the lazy dog")
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Function
    $Name = "Function"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        function Get-RandomSquare {
            $r = Get-Random
            return ($r * $r)
        }
        for ($i = 0; $i -lt 1000; $i++) {
            $x = Get-RandomSquare
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Functional Code
    $Name = "Functional Code"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        for ($i = 0; $i -lt 1000; $i++) {
            $s = Get-Random
            $y = ($s * $s)
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Class
    $Name = "Class"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        class MyMath {
            static [int] CountRealHigh() {
                $x = 0
                foreach ($i in 1..50000) {
                    $x++
                }
                return $x
            }
        }
        [MyMath]::CountRealHigh()
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Class Code
    $Name = "Class Code"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $y = 0
        foreach ($i in 1..50000) {
                $y++
        }
        $y
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region .Count
    $Name = ".Count"
    $Iterations = 100
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Array1 = 1..10000
        for ($i = 0; $i -lt $Array1.Count; $i++) {
            $Array1[$i]++
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Variable
    $Name = "Variable"
    $Iterations = 10
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $Array2 = 1..10000
        $Limit = $Array2.Count
        for ($j = 0; $j -lt $Limit; $j++) {
            $Array2[$j]++
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Evaluation Order Good
    $Name = "Good Evaluation Order"
    $Iterations = 100
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $x = $true
        $y = 1000
        $z = 's'
        $c = 0
        if ($x -eq $true -or $y -gt 1000 -or $z -eq 't') {
            $c++
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    #region Evaluation Order Bad
    
    $Name = "Bad Evaluation Order"
    $Iterations = 100
    $CTest++
    Write-Progress -Id 0 -Activity "[$($CTest)/$($TotalTest)] Running Performance Comparisons" -CurrentOperation "Testing $($Name) $($Iterations) times" -PercentComplete ($CTest/$TotalTest * 100)
    $Result = Test-Performance -Count $Iterations -ScriptBlock {
        $x = $true
        $y = 1000
        $z = 's'
        $c = 0
        if ($y -gt 1000 -or $z -eq 't' -or $x -eq $true) {
            $c++
        }
    }
    $CsvWriter.WriteLine("$($Name),$($Iterations),$($Result.Sum),$($Result.Mean),$($Result.Median),$($Result.Minimum),$($Result.Maximum),$($Result.Range),$($Result.Variance),$($Result.StdDeviation),`"$($Result.Occurrence -Join ',')`"")
    #endregion

    Write-Host "Completed $($CTest) tests" -ForegroundColor Magenta
    #WRAP UP
    $CsvWriter.Close()
    #endregion
} else {
    switch($Test) {
        0 {
            #SETUP
            $LeftTitle = "Filter"
            $RightTitle = "Where-Object"
            $Iterations = 10
            if ($PROFILE -match "/home/.*") {
                $Path = "/etc"
                $Filter = ".d"
            } else {
                $Path = "C:\Windows\System32"
                $Filter = ".exe"
            }
    
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            
            #EXECUTE
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $ObjsA = Get-ChildItem -Path $Path -Filter "*$($Filter)"
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $ObjsB = Get-ChildItem -Path $Path | Where-Object {$_.Extension -eq $Filter}
            }
        }
        1 {
            #SETUP
            $LeftTitle = "ForEach"
            $RightTitle = "For"
            $Iterations = 10
            $Test1ArrayLeft = New-TestObjectArray -Size 10000
            $Test1ArrayRight = New-TestObjectArray -Size 10000

            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
    
            #EXECUTE
            $Left = Test-Performance -Count $Iterations -PassedObj $Test1ArrayLeft -ScriptBlock {
                param([Object[]]$obj)
                foreach ($i in $obj) {
                    $i.Number = Get-Random
                }
            }
            $Right = Test-Performance -Count $Iterations -PassedObj $Test1ArrayRight -ScriptBlock {
                param([Object[]]$obj)
                for ($j = 0; $j -lt 1000; $j++) {
                    $obj[$j].Number = Get-Random
                }
            }
            Remove-Variable Test1ArrayLeft
            Remove-Variable Test1ArrayRight
        }
        2 {
            #SETUP
            $LeftTitle = "ForEach"
            $RightTitle = ".ForEach()"
            $Test2LArray = New-TestObjectArray -Size 10000
            $Test2RArray = New-TestObjectArray -Size 10000
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -PassedObj $Test2LArray -ScriptBlock {
                param([Object[]]$obj)
                foreach ($i in $obj) {
                    $i.Number = Get-Random
                }
            }
            $Right = Test-Performance -Count $Iterations -PassedObj $Test2RArray -ScriptBlock {
                param([Object[]]$obj)
                $obj.ForEach{$_.Number = Get-Random}
            }
            Remove-Variable Test2LArray
            Remove-Variable Test2RArray
        }
        3 {
            #SETUP
            $LeftTitle = "Write-Host"
            $RightTitle = "Write-Information"
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Test3LArray = New-TestObjectArray -Size 1000
            $Test3RArray = New-TestObjectArray -Size 1000
            $Iterations = 10
    
            #EXECUTE
            $Left = Test-Performance -SuppressStreams -PassedObj $Test3LArray -Count $Iterations -ScriptBlock {
                Param([Object[]]$Obj)
                foreach ($item in $Obj) {
                    Write-Host $item.Word
                }
            }
            $Right = Test-Performance -SuppressStreams -PassedObj $Test3RArray -Count $Iterations -ScriptBlock {
                Param([Object[]]$Obj)
                foreach ($item in $Obj) {
                    Write-Information $item.Word
                }
            }
            Remove-Variable Test3LArray
            Remove-Variable Test3RArray
        }
        4 {
            #SETUP
            $LeftTitle = "ForEach"
            $RightTitle = "| ForEach-Object"
            $Iterations = 10
            $Test4LArray = New-TestObjectArray  -Size 10000
            $Test4RArray = New-TestObjectArray -Size 10000
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -PassedObj $Test4LArray -ScriptBlock {
                param([Object[]]$obj)
                foreach ($item in $obj) {
                    $item.Number = Get-Random
                }
            }
            $Right = Test-Performance -Count $Iterations -PassedObj $Test4RArray -ScriptBlock {
                param([Object[]]$obj)
                $obj | ForEach-Object -Process {
                    $_.Number = Get-Random
                }
            }
            Remove-Variable Test4LArray
            Remove-Variable Test4RArray
        }
        5 {
            #SETUP
            $LeftTitle = "Array"
            $RightTitle = "ArrayList"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $Array = @()
                for ($i = 0; $i -lt 10000; $i++) {
                    $Array += $i
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $ArrayList = [System.Collections.ArrayList]::new()
                for($i = 0; $i -lt 10000; $i++) {
                    [void]$ArrayList.Add($i)
                }
            }
        }
        6 {
            #SETUP
            $LeftTitle = "ArrayList"
            $RightTitle = "Generic List"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $ArrayList = [System.Collections.ArrayList]::new()
                for($i = 0; $i -lt 10000; $i++) {
                    [void]$ArrayList.Add($i)
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $List = [System.Collections.Generic.List[Object]]::new()
                for($i = 0; $i -lt 10000; $i++) {
                    [void]$List.Add($i)
                }
            }
        }
        7 {
            #SETUP
            $LeftTitle = "Object List"
            $RightTitle = "Type List"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $ObjectList = [System.Collections.Generic.List[Object]]::new()
                for($i = 0; $i -lt 10000; $i++) {
                    [void]$ObjectList.Add($i)
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $TypeList = [System.Collections.Generic.List[int]]::new()
                for($i = 0; $i -lt 10000; $i++) {
                    [void]$TypeList.Add($i)
                }
            }
        }
        8 {
            #SETUP
            $LeftTitle = "Replace Method"
            $RightTitle = "Regex.Replace"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $Haystack = "The Quick Brown Fox Jumped Over the Lazy Dog 5 Times"
                $Needle = "5"
                for ($i = 0; $i -lt 10000; $i++) {
                    [void]$Haystack.Replace($Needle, (Get-Random))
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $Haystack = "The Quick Brown Fox Jumped Over the Lazy Dog 5 Times"
                $Needle = "\ ([\d]*)\ "
                for ($i = 0; $i -lt 10000; $i++) {
                    [void]([regex]::Replace($Haystack, $Needle, " $(Get-Random) "))
                }
            }
        }
        9 {
            #SETUP
            $LeftTitle = "Pipes"
            $RightTitle = "Long Form"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $RSa = Get-Service | Where-Object {$_.Status -eq 'Running'} | Select-Object Name | Sort-Object -Property Name
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               $Services = Get-Service
               $RunningServices = [System.Collections.Generic.List[Object]]::new()
               foreach ($Svc in $Services) {
                    if ($Svc.Status -eq 'Running') {
                        [void]$RunningServices.Add($Svc.Name)
                   }
               }
               $RunningServices.Sort()
               $RSb = $RunningServices.ToArray()
            }
        }
        10 {
            #SETUP
            $LeftTitle = "StringBuilder"
            $RightTitle = "+="
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
               $String1 = "" 
               $sb = [System.Text.StringBuilder]::new()
               for ($i = 0; $i -lt 10000; $i++) {
                   [void]$sb.Append('A')
               }
               $String1 = $sb.ToString()
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               [string]$String2 = ""
               for ($i = 0; $i -lt 10000; $i++) {
                   $String2 += 'B'
               }
            }
        }
        11 {
            #SETUP
            $LeftTitle = "Composite Formatting"
            $RightTitle = "Interpolated Formatting"
            $Iterations = 1000
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $x = "A"
                $y = "B"
                $String3 = [string]::Format("{0} {1}", $x, $y)
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               $x = "C"
               $y = "D"
               $String4 = "$($x) $($y)"
            }
        }
        12 {
            #SETUP
            $LeftTitle = "Get-Content"
            $RightTitle = ".NET Stream"
            $Iterations = 1000

            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $Stuff = Get-Content "$($PSScriptRoot)/Item1.txt" -Encoding UTF8
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               $Contents = [System.Collections.Generic.List[String]]::new()
               $StreamReader = [System.IO.StreamReader]::new("$($PSScriptRoot)/Item1.txt", [System.Text.Encoding]::UTF8)
               while ($StreamReader.Peek() -ne -1) {
                   [void]$Contents.Add($StreamReader.ReadLine())
               }
               $More = $Contents.ToArray()
               #$More = $StreamReader.ReadToEnd()
            }
        }
        13 {
            #SETUP
            $LeftTitle = "[void]"
            $RightTitle = "| Out-Null"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $vl = [System.Collections.Generic.List[int]]::new()
                for ($i = 0; $i -lt 1000; $i++) {
                    [void]$vl.Add((Get-Random))
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $on = [System.Collections.Generic.List[int]]::new()
                for ($i = 0; $i -lt 1000; $i++) {
                    $on.Add((Get-Random)) | Out-Null
                }
            }
        }
        14 {
            #SETUP
            $LeftTitle = "Write-Host"
            $RightTitle = "Write-Output"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                for ($i =0; $i -lt 100; $i++) {
                    Write-Host "The quick brown fox jumps over the lazy dog"
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                for ($i =0; $i -lt 100; $i++) {
                    Write-Output "The quick brown fox jumps over the lazy dog"
                }
            }
        }
        15 {
            #SETUP
            $LeftTitle = "Write-Output"
            $RightTitle = "[Console]::WriteLine()"
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                for ($i = 0; $i -lt 100; $i++) {
                    Write-Output "The quick brown fox jumps over the lazy dog"
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               for ($i = 0; $i -lt 100; $i++) {
                    [Console]::WriteLine("The lazy dog jumps over the quick brown fox")
                }
            }
        }
        16 {
            #SETUP
            $LeftTitle = "Function"
            $RightTitle = "Code"
            function Get-RandomSquare {
                $r = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
                return ($r * $r)
            }
            $Iterations = 10
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -Count $Iterations -ScriptBlock {    
                for ($i = 0; $i -lt 1000; $i++) {
                    $x = Get-RandomSquare
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
               for ($i = 0; $i -lt 1000; $i++) {
                   $s = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
                   $y = ($s * $s)
               }
            }
        }
        17 {
            #SETUP
            $LeftTitle = "Class"
            $RightTitle = "Code"
            $Iterations = 10
            class MyMath {
                static [int64] GetRandomSquare() {
                    $x = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
                    return $x * $x
                }
            }
    
            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Left = Test-Performance -SuppressStreams -Count $Iterations -ScriptBlock {
                for ($i = 0; $i -lt 1000; $i++) {
                    [MyMath]::GetRandomSquare()
                }
            }
            $Right = Test-Performance -SuppressStreams -Count $Iterations -ScriptBlock {
                for ($i = 0; $i -lt 1000; $i++) {
                    $s = Get-Random -Maximum ([int][Math]::Sqrt([int]::MaxValue))
                    ($s * $s)
                }
            }
        }
        18 {
            #SETUP
            $LeftTitle = "Path"
            $RightTitle = "Get-ChildItem -Filter"
            $Iterations = 10
    
            #EXECUTE
            if ($PROFILE -match '/home/.*') {
                Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
                $Left = Test-Performance -Count $Iterations -ScriptBlock {
                    Get-ChildItem '/etc/*.d'
                }
                $Right = Test-Performance -Count $Iterations -ScriptBlock {
                Get-ChildItem '/etc' -Filter '*.d'
                }
            } else {
                Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
                $Left = Test-Performance -SuppressStreams -Count $Iterations -ScriptBlock {
                    Get-ChildItem 'C:\Windows\inf\*.inf'
                }
                $Right = Test-Performance -SuppressStreams -Count $Iterations -ScriptBlock {
                Get-ChildItem 'C:\Windows\inf' -Filter '*.inf'
                }
            }
        }
        19 {
            #SETUP
            $LeftTitle = '.Count'
            $RightTitle = '$Variable'
            $Iterations = 100
            $Array1 = 1..10000
            $Array2 = 1..10000

            #EXECUTE
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
    
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                for ($i = 0; $i -lt $Array1.Count; $i++) {
                    $Array1[$i]++
                }
            }
            $Right = Test-Performance -Count $Iterations -ScriptBlock {
                $Limit = $Array2.Count
                for ($j = 0; $j -lt $Limit; $j++) {
                    $Array2[$j]++
                }
            }
        }
        20 {
            #SETUP
            $LeftTitle = "Good Order"
            $RightTitle = "Bad Order"
            Write-Host "Pitting $($LeftTitle) against $($RightTitle)..." -ForegroundColor Cyan
            $Iterations = 1000
    
            #EXECUTE
            $Left = Test-Performance -Count $Iterations -ScriptBlock {
                $Continue = $false
                $Value = Get-Random -Maximum 1000
                $String = "Hello World"
                if ($Continue -and ($String -match "World" -and $Value -lt 500)) {
                    $x = 100
                }
            }
            $Right = Test-Performance -SuppressStreams -PassedObj $Test20RArray -Count $Iterations -ScriptBlock {
                $Continue = $false
                $Value = Get-Random -Maximum 1000
                $String = "Hello World"
                if (($Value -lt 500 -and $String -match "World") -and $Continue){
                    $x = 100
                }
            }
        }
    }

    #WRAP UP
    Get-Winner -AName $LeftTitle -AValue $Left.Median -BName $RightTitle -BValue $Right.Median
    Write-Host ""
    Write-Host "Stats for $($LeftTitle)" -ForegroundColor Cyan
    $Left
    Write-Host "Stats for $($RightTitle):" -ForegroundColor Cyan
    $Right
}
#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$ModuleRoot = $PSScriptRoot

# Find user defined paths
Get-Content $ModuleRoot\dots.conf |
    Where-Object {$_ -match "^\s*ScriptsPath\s*=\s*|^\s*ConfPath\s*=\s*|^\s*DataPath\s*=\s*"} |
    Foreach-Object {
        $Name = ($_ -split '=')[0].trim()
        $Value = ($_ -split '=')[1].trim()
        $Value = $Value -replace '\$ModuleRoot', $ModuleRoot
        $Value = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)
        Set-Variable -Name $Name -Value $Value -Force
    }
# No, or bad user defined paths?
foreach($Folder in 'Conf', 'Data', 'Scripts') {
    $Path = $null
    $Path = Get-Variable -Name "${Folder}Path" -ValueOnly -ErrorAction SilentlyContinue
    if(-not $Path) {
        $Path = Join-Path $ModuleRoot "${Folder}Path"
        Set-Variable -Name "${Folder}Path" -Value $Path
    }
    if(-not (Test-Path $Path -PathType Container)) {
        throw "The ${Folder}Path [$Path] does not exist.`nCreate this, or fix it in your [$ModuleRoot\dots.conf]"
    }
}
# Resolve paths we're use somewhat often
$AutoPath = (Resolve-Path "$ScriptsPath\Auto").Path
$ManualPath = (Resolve-Path "$ScriptsPath\Manual").Path
$SortPath = Join-Path $ConfPath sort.txt

#Dot source the files
Foreach($import in @($Public + $Private)) {
    try {
        . $import.fullname
    }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Load the dots config
. $(Join-Path $ConfPath Dots.Config.ps1)

Export-ModuleMember -Function $Public.Basename

#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$ModuleRoot = $PSScriptRoot

# Find user defined paths
$ConfData = Get-Content $ModuleRoot\dots.conf
'ScriptsPath', 'ConfPath', 'DataPath' | Foreach-Object {
    $PathType = $_
    #Check conf data for paths
    $Line = $ConfData | Where-Object {$_ -match "^\s*$PathType\s*=\s*"}
    if($Line){
        $Value = ($Line -split '=')[1].trim()
        $Value = $Value -replace '\$ModuleRoot', $ModuleRoot
        $Value = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)
        Set-Variable -Name $PathType -Value $Value -Force
    }
    # Override paths with env vars
    if($Value = (Get-Item ENV:$PathType -ErrorAction SilentlyContinue).Value) {
        $Value = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)
        Set-Variable -Name $PathType -Value $Value -Force
    }

    # Check for nonexistent paths
    $Path = Get-Variable -Name $PathType -ValueOnly -ErrorAction SilentlyContinue
    if(-not $Path) {
        $Path = Join-Path $ModuleRoot $PathType
        Set-Variable -Name $PathType -Value $Path -Force
    }
    if(-not (Test-Path $Path -PathType Container)) {
        throw "The [$PathType] [$Path] does not exist.`nCreate this, or fix it in your [$ModuleRoot\dots.conf]"
    }
}

# Resolve paths we'll use somewhat often
$ExternalSourcesScriptsPath = (Resolve-Path "$ScriptsPath\ExternalSources").Path
$DotsSourcesScriptPath = (Resolve-Path "$ScriptsPath\DotsSources").Path
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

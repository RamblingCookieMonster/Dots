#Get public and private function definition files.
$Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )
$ModuleRoot = $PSScriptRoot

#Dot source the files
Foreach($import in @($Public + $Private)) {
    try {
        . $import.fullname
    }
    catch {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

# Find user defined paths
$DotsConfig = Get-DotsConfig
foreach($Key in $DotsConfig.Keys) {
    Set-Variable -Name $Key -Value $DotsConfig[$Key] -Force
}

# Resolve paths we'll use somewhat often
$ExternalSourcesScriptsPath = (Resolve-Path "$ScriptsPath\ExternalSources").Path
$DotsSourcesScriptPath = (Resolve-Path "$ScriptsPath\DotsSources").Path
$SortPath = Join-Path $ConfPath sort.txt

# Load the dots config
. $(Join-Path $ConfPath Dots.Config.ps1)

Export-ModuleMember -Function $Public.Basename

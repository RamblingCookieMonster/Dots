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

$DotsProps = 'CMDBPrefix',
             'ScriptsPath',
             'DataPath',
             'ScriptOrder',
             'ScriptsToRun',
             'ScriptsToIgnore',
             'ServerUnique',
             'TestMode'
$DotsConfig = [pscustomobject]@{} | Select-Object $DotsProps
$_DotsConfigXmlpath = Get-DotsConfigPath
if(-not (Test-Path -Path $_DotsConfigXmlpath -ErrorAction SilentlyContinue)) {
    try {
        Write-Warning "Did not find config file [$_DotsConfigXmlpath], attempting to initialize"
        Initialize-DotsConfig -Path $_DotsConfigXmlpath -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to create config file [$_DotsConfigXmlpath]: $_"
    }
}
else {
    $DotsConfig = Get-DotsConfig -Source Xml
}

# Create variables for config props, for convenience
# We also do this in Set/Initialize commands
foreach($Prop in $DotsProps) {
    Set-Variable -Name $Prop -Value $DotsConfig.$Prop -Force
}

# Resolve paths we'll use somewhat often
$ExternalSourcesScriptPath = (Resolve-Path "$ScriptsPath\ExternalSources").Path
$DotsSourcesScriptPath = (Resolve-Path "$ScriptsPath\DotsSources").Path

Export-ModuleMember -Function $Public.Basename

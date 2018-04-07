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
             'ServerUnique',
             'TestMode',
             'BaseUri',
             'Credential'
$DotsConfig = [pscustomobject]@{} | Select-Object $DotsProps
$_DotsConfigXmlpath = Get-DotsConfigPath
Write-Host "_DotsConfigXmlpath is $_DotsConfigXmlpath"
if(-not (Test-Path -Path $_DotsConfigXmlpath -ErrorAction SilentlyContinue)) {
    try {
        Write-Warning "Did not find config file [$_DotsConfigXmlpath], attempting to initialize"
        Initialize-DotsConfig -Path $_DotsConfigXmlpath
        Write-Host "DotsConfig initialized $($DotsConfig | Out-String)"
    }
    catch {
        Write-Warning "Failed to create config file [$_DotsConfigXmlpath]: $_"
    }
}
else {
    $DotsConfig = Get-DotsConfig -Source Xml
    Write-Host "DotsConfig imported $($DotsConfig | Out-String)"
}

# Create variables for config props, for convenience
foreach($Prop in $DotsProps) {
    Write-Host "Set $Prop to $($DotsConfig.$Prop)"
    Set-Variable -Name $Prop -Value $DotsConfig.$Prop -Force
}

# Resolve paths we'll use somewhat often
$ExternalSourcesScriptsPath = (Resolve-Path "$ScriptsPath\ExternalSources").Path
$DotsSourcesScriptPath = (Resolve-Path "$ScriptsPath\DotsSources").Path

Export-ModuleMember -Function $Public.Basename

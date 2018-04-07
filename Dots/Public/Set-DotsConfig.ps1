function Set-DotsConfig {
    <#
    .SYNOPSIS
        Set Dots module configuration.

    .DESCRIPTION
        Set Dots module configuration, and $DotsConfig module variable.

        WARNING: Use this to store your PSNeo4j credential on a filesystem at your own risk.
                 We use the DPAPI to store this.  This credential serialization only happens on Windows

    .PARAMETER CMDBPrefix
        Prefix for Dots-owned data, when multiple data sources are present

    .PARAMETER ScriptsPath
        Path to scripts that pull external and Dots data
        Must include scripts in respective subfolders: ExternalSources, DotsSources

    .PARAMETER DataPath
        Path to yaml data where Dots is the source of truth

    .PARAMETER ScriptOrder
        Controls order of ScriptsPath script execution
        Items not included run last
        Required in cases where data must exist first - e.g. start and end nodes for a relationship

    .PARAMETER ServerUnique
        Unique identifier for a :Server.  Used to correlate and to avoid duplicates

    .PARAMETER TestMode
        If specified, we generate Dots from pre-existing mock data

    .PARAMETER BaseUri
        BaseUri for PSNeo4j

    .PARAMETER Credential
        Credential for PSNeo4j

    .PARAMETER Path
        If specified, save config file to this file path
        Defaults to
          DotsConfig.xml in the user temp folder on Windows, or
          .dotsconfig in the user's home directory on Linux/macOS

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding()]
    param(
        [string]$CMDBPrefix,
        [string]$DataPath,
        [string]$ScriptsPath,
        [string[]]$ScriptOrder,
        [string]$ServerUnique,
        [switch]$TestMode,
        [string]$BaseUri,
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        [string]$Path = $script:_DotsConfigXmlpath
    )

    Switch ($PSBoundParameters.Keys)
    {
        'CMDBPrefix'   { $Script:DotsConfig.CMDBPrefix = $CMDBPrefix }
        'DataPath'     { $Script:DotsConfig.DataPath = $DataPath }
        'ScriptsPath'  { $Script:DotsConfig.ScriptsPath = $ScriptsPath }
        'ScriptOrder'  { $Script:DotsConfig.ScriptOrder = [string[]]$ScriptOrder }
        'ServerUnique' { $Script:DotsConfig.ServerUnique = $ServerUnique }
        'TestMode'     { $Script:DotsConfig.TestMode = [bool]$TestMode }
        'BaseUri'      { $Script:DotsConfig.BaseUri = $BaseUri }
        'Credential'   { $Script:DotsConfig.Credential = $Credential }
    }
    # Create variables for config props, for convenience
    foreach($Prop in $DotsProps) {
        Write-Host "Set $Prop to $($DotsConfig.$Prop)"
        Set-Variable -Name $Prop -Value $DotsConfig.$Prop -Scope Script -Force
    }
    $SelectParams = @{
        Property = $Script:DotsProps
    }
    if(-not (Test-IsWindows)) {
        $SelectParams.Add('ExcludeProperty', 'Credential')
    }
    #Write the global variable and the xml
    $Script:DotsConfig |
        Select-Object @SelectParams |
        Export-Clixml -Path $Path -Force
}
<#
# Check for nonexistent paths
        $Path = $Output.$PathType
        if(-not $Path) {
            $Path = Join-Path $ModuleRoot $PathType
            $Output.$PathType = $Path
        }
        if(-not (Test-Path $Path -PathType Container)) {
            throw "The [$PathType] [$Path] does not exist.`nCreate this, or fix it in your [$ModuleRoot\dots.conf]"
        }

        #>
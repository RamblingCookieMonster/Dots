function Set-DotsConfig {
    <#
    .SYNOPSIS
        Set Dots module configuration

    .DESCRIPTION
        Set Dots module configuration, and $DotsConfig module variable

    .PARAMETER CMDBPrefix
        Prefix for Dots-owned data, when multiple data sources are present

    .PARAMETER ScriptsPath
        Path to scripts that pull external and Dots data
        Must include scripts in respective subfolders: ExternalSources, DotsSources

        If more than one ScriptsPath is specified and duplicate script names are found,
        we pick the first script found

    .PARAMETER DataPath
        Path to yaml data where Dots is the source of truth

    .PARAMETER ScriptOrder
        Controls order of ScriptsPath script execution
        Items not included run last
        Required in cases where data must exist first - e.g. start and end nodes for a relationship

    .PARAMETER ScriptsToRun
        Specify a whitelist of scripts that Dots will run
        All other scripts will be ignored

    .PARAMETER ScriptsToIgnore
        Specify a blacklist of scripts that Dots will ignore
        All other scripts will run

    .PARAMETER ServerUnique
        Unique identifier for a :Server.  Used to correlate and to avoid duplicates

    .PARAMETER TestMode
        If specified, we generate Dots from pre-existing mock data

    .PARAMETER Path
        If specified, save config file to this file path
        Defaults to
          * DotsConfig.xml in the user temp folder on Windows, or
          * .dotsconfig in the user's home directory on Linux/macOS

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding()]
    param(
        [string]$CMDBPrefix,
        [string[]]$DataPath,
        [string[]]$ScriptsPath,
        [string[]]$ScriptOrder,
        [string[]]$ScriptsToRun,
        [string[]]$ScriptsToIgnore,
        [string]$ServerUnique,
        [switch]$TestMode,
        [string]$Path = $script:_DotsConfigXmlpath
    )

    Switch ($PSBoundParameters.Keys)
    {
        'CMDBPrefix'      { $Script:DotsConfig.CMDBPrefix = $CMDBPrefix }
        'DataPath'        { $Script:DotsConfig.DataPath = [string[]]$DataPath }
        'ScriptsPath'     { $Script:DotsConfig.ScriptsPath = [string[]]$ScriptsPath }
        'ScriptOrder'     { $Script:DotsConfig.ScriptOrder = [string[]]$ScriptOrder }
        'ScriptsToRun'    { $Script:DotsConfig.ScriptsToRun = [string[]]$ScriptsToRun }
        'ScriptsToIgnore' { $Script:DotsConfig.ScriptsToIgnore = [string[]]$ScriptsToIgnore }
        'ServerUnique'    { $Script:DotsConfig.ServerUnique = $ServerUnique }
        'TestMode'        { $Script:DotsConfig.TestMode = [bool]$TestMode }
    }
    # Create variables for config props, for convenience
    foreach($Prop in $DotsProps) {
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

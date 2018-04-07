function Initialize-DotsConfig {
    <#
    .SYNOPSIS
        Initialize Dots module configuration

    .DESCRIPTION
        Initialize Dots module configuration, and $DotsConfig module variable

        This will set Dots back to the defaults, with overrides as specified by parameters

        WARNING: Use this to store your PSNeo4j credential on a filesystem at your own risk.
                 We use the DPAPI to store this.  This credential serialization only happens on Windows

    .PARAMETER CMDBPrefix
        Prefix for Dots-owned data, when multiple data sources are present
        Defaults to Dots

        For example, a :Server might include properties with the following prefixes:
          * AD:   Active Directory data             e.g. ADOperatingSystem
          * PDB:  PuppetDB data                     e.g. PDBosfamily
          * Dots: Data stored or generated by Dots  e.g. DotsADUpdateDate

    .PARAMETER ScriptsPath
        Path to scripts that pull external and Dots data
        Must include scripts in respective subfolders: ExternalSources, DotsSources
        Defaults to Dots/Scripts

    .PARAMETER DataPath
        Path to yaml data where Dots is the source of truth
        Defaults to Dots/Data

    .PARAMETER ScriptOrder
        Controls order of ScriptsPath script execution
        Items not included run last
        Required in cases where data must exist first - e.g. start and end nodes for a relationship

    .PARAMETER ServerUnique
        Unique identifier for a :Server.  Used to correlate and to avoid duplicates
        Defaults to ${CMDBPrefix}Hostname

    .PARAMETER TestMode
        If specified, we generate Dots from pre-existing mock data

    .PARAMETER BaseUri
        BaseUri for PSNeo4j
        Defaults to http://127.0.0.1:7474

    .PARAMETER Credential
        Credential for PSNeo4j
        Serializing this to disk is not supported in cross platform scenarios
        Defaults to neo4j:neo4j

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
        [string]$CMDBPrefix = 'Dots',
        [string]$DataPath = $(Join-Path $ModuleRoot 'Data'),
        [string]$ScriptsPath = $(Join-Path $ModuleRoot 'Scripts'),
        [string[]]$ScriptOrder = @( 'ADComputers',
                                  'ADUsers',
                                  'ADGroups',
                                  'PuppetDB',
                                  'Service',
                                  'Service-DependsOn' ),
        [string]$ServerUnique, # Default is computed below
        [switch]$TestMode,
        [string]$BaseUri = 'http://127.0.0.1:7474',
        [ValidateNotNull()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]
        $Credential,
        [string]$Path = $script:_DotsConfigXmlpath
    )
    if(-not $PSBoundParameters.ContainsKey('ServerUnique')) {
        $ServerUnique = "${CMDBPrefix}Hostname"
        $PSBoundParameters.Add('ServerUnique', $ServerUnique)
    }
    if(-not $PSBoundParameters.ContainsKey('Credential')) {
        $Password = ConvertTo-SecureString -String "neo4j" -AsPlainText -Force
        $Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'neo4j', $Password
        $PSBoundParameters.Add('Credential', $Credential)
    }
    Switch ($DotsProps)
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

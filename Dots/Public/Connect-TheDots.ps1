function Connect-TheDots {
    <#
    .SYNOPSIS
        Extract data from sources, load into Neo4j

    .DESCRIPTION
        Extract data from sources, load into Neo4j

        Warning:  If you do not connect all the dots,
                  some relationship data will not be restored until you run them all again
                  Many DotsSource scripts remove dots and relationships before re-creating

    .PARAMETER DataSource
        Limit which scripts to run by data source:  ExternalSources, or DotsSources

    .PARAMETER Include
        Limit which scripts run to this whitelist.  Accepts wildcards

    .PARAMETER Exclude
        Limit which scripts run by ignoring these blacklisted scripts.  Accepts wildcards

    .PARAMETER Dependencies
        Identify which scripts must run before other scripts via this hash table
        Using the DotsConfig -ScriptOrder is preferable

        Key is script that has dependencies.  Value is an array of scripts the Key script depends on

        Example ensuring DataSourceFirst1 and DataSourceFirst2 run before DataSource1:
        @{
            DataSource1 = 'DataSourceFirst1', 'DataSourceFirst2'
        }

    .PARAMETER ScriptParameters
        A way to set parameters for Dots scripts

        # Generally:
        -ScriptParameters @{
            DotsScriptName = @{
                Some = 'Parameters'
                To   = 'Splat'
            }
            DotsScriptName2 = @{
                Another = 'one'
            }
        }

    .EXAMPLE
        Connect-TheDots -Whatif
        # Show what would happen if we ran Connect-TheDots

    .EXAMPLE
        Connect-TheDots -Confirm:$False
        # Connect the dots!

    .EXAMPLE
        Connect-TheDots -Include ADComputers
        # Connect only the ADComputers dots

    .EXAMPLE
        Connect-TheDots -ScriptParameters @{
            Racktables = @{
                BaseUri = 'https://fqdn.racktables/rackfacts/systems
            }
            ADComputers = @{
                ExcludeOlderThanMonths = 3
            }
        }

        # Run Connect-TheDots, and set...
           # the BaseUri parameter on the RackTables script
           # the ExcludeOlderThanMonths parameter on the ADComputers script

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding( SupportsShouldProcess = $True,
                    ConfirmImpact='High' )]
    param(
        [validateset('ExternalSources', 'DotsSources')]
        [string]$DataSource,
        [string[]]$Include,
        [string[]]$Exclude,
        [hashtable]$Dependencies,
        [hashtable[]]$ScriptParameters,
        [switch]$Show
    )
    $GetScriptParams = @{}
    'DataSource', 'Include', 'Exclude', 'Dependencies' | Foreach-Object {
        if($PSBoundParameters.ContainsKey($_)){
            $GetScriptParams.add($_,$PSBoundParameters[$_])
        }
    }
    $Scripts = Get-DotsScript @GetScriptParams
    Write-Verbose "Running Scripts: $($Scripts.FullName | Out-String)"
    foreach($Script in $Scripts) {
        if ( $PSCmdlet.ShouldProcess( "Connected the dots '$($Script.Fullname)'",
                                      "Connect the dots '$($Script.Fullname)'?",
                                      "Connecting dots" )
        ) {
            try {
                $Basename = $Script.Basename
                $Params = @{ErrorAction = 'Stop'}
                if($ScriptParameters.ContainsKey($Basename) -and $ScriptParameters.$Basename -is [hashtable]){
                    $Params = $ScriptParameters.$Basename
                }
                Write-Verbose "Dot sourcing [$($Script.Fullname)] with params`n $($Params | Out-String)"
                . $Script.FullName @Params
            }
            catch {
                Write-Error $_
            }
        }
    }
    Write-Verbose "Dots Connected!"
}
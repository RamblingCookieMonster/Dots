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

    .EXAMPLE
        Connect-TheDots -Whatif
        # Show what would happen if we ran Connect-TheDots

    .EXAMPLE
        Connect-TheDots -Confirm:$False
        # Connect the dots!

    .EXAMPLE
        Connect-TheDots -Include ADComputers
        # Connect only the ADComputers dots

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
        [switch]$Show
    )
    $Scripts = Get-DotsScript @PSBoundParameters

    Write-Verbose "Running Scripts: $($Scripts.FullName | Out-String)"
    foreach($Script in $Scripts) {
        if ( $PSCmdlet.ShouldProcess( "Connected the dots '$($Script.Fullname)'",
                                      "Connect the dots '$($Script.Fullname)'?",
                                      "Connecting dots" )
        ) {
            try {
                Write-Verbose "Dot sourcing [$Script]"
                . $Script -ErrorAction Stop
            }
            catch {
                Write-Error $_
            }
        }
    }
    Write-Verbose "Dots Connected!"
}
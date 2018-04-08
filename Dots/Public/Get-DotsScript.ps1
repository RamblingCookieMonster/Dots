function Get-DotsScript {
    <#
    .SYNOPSIS
        Get Dots scripts

    .DESCRIPTION
        Get Dots scripts

    .PARAMETER DataSource
        Limit which scripts are returned by data source:  ExternalSources, or DotsSources

    .PARAMETER Include
        Limit which scripts are returned to this whitelist.  Accepts wildcards

    .PARAMETER Exclude
        Limit which scripts are returned by ignoring these blacklisted scripts.  Accepts wildcards

    .PARAMETER Dependencies
        Identify and sort which scripts must run before other scripts via this hash table
        Using the DotsConfig -ScriptOrder is preferable

        Key is script that has dependencies.  Value is an array of scripts the Key script depends on

        Example ensuring DataSourceFirst1 and DataSourceFirst2 run before DataSource1:
        @{
            DataSource1 = 'DataSourceFirst1', 'DataSourceFirst2'
        }

    .EXAMPLE
        Get-DotsScript
        # Show all Dots scripts

    .EXAMPLE
        Get-DotsScript -Include *AD*
        # Show Dots scripts with a name like *AD*

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding()]
    param(
        [validateset('ExternalSources', 'DotsSources')]
        [string]$DataSource,
        [string[]]$Include,
        [string[]]$Exclude,
        [hashtable]$Dependencies
    )
    $Scripts = Get-ChildItem $ScriptsPath -Recurse -Include *.ps1
    Write-Verbose "Found scripts $($Scripts.FullName | Out-String)"
    if($Script:ScriptsToRun.count -gt 0) {
        $Scripts = foreach($Script in $Scripts) {
            foreach($Name in $Script:ScriptsToRun) {
                if($Script.BaseName -Like $Name) {
                    $Script
                    break
                }
            }
        }
        Write-Verbose "Including only ScriptsToRun (See Get-DotsConfig) scripts: $($Scripts.FullName | Out-String)"
    }
    if($Script:ScriptsToIgnore.count -gt 0) {
        $ResolvedExcludes = foreach($Script in $Scripts) {
            foreach($Name in $Script:ScriptsToIgnore) {
                if($Script.BaseName -like $Name) {
                    $Script.FullName
                    break
                }
            }
        }
        $Scripts = $Scripts | Where-Object {$ResolvedExcludes -NotContains $_}
        Write-Verbose "Excluding ScriptsToIgnore (see Get-DotsConfig) scripts: $($Scripts.FullName | Out-String)"
    }
    if($DataSource -eq 'ExternalSources') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$Script:ExternalSourcesScriptPath*"}
        Write-Verbose "Including only ExternalSources scripts: $($Scripts.FullName | Out-String)"
    }
    if($DataSource -eq 'DotsSources') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$Script:DotsSourcesScriptPath*" }
        Write-Verbose "Including only DotsSources scripts: $($Scripts.FullName | Out-String)"
    }
    if($Include) {
        $Scripts = foreach($Script in $Scripts) {
            foreach($Name in $Include) {
                if($Script.BaseName -Like $Name) {
                    $Script
                    break
                }
            }
        }
        Write-Verbose "Including only -include scripts: $($Scripts.FullName | Out-String)"
    }
    if($Exclude) {
        $ResolvedExcludes = foreach($Script in $Scripts) {
            foreach($Name in $Exclude) {
                if($Script.BaseName -like $Name) {
                    $Script.FullName
                    break
                }
            }
        }
        $Scripts = $Scripts | Where-Object {$ResolvedExcludes -NotContains $_}
        Write-Verbose "Excluding specified scripts: $($Scripts.FullName | Out-String)"
    }
    # Sort by file first, then dependencies (dependencies should override)
    if($Script:ScriptOrder) {
        $Scripts = $Scripts | Sort-CustomList -List $Script:ScriptOrder -SortOnProperty BaseName
        Write-Verbose "Sorting scripts with order [$Script:ScriptOrder]"
    }
    if($Dependencies) {
        $DependencyOrder = Get-TopologicalSort $Dependencies
        $Scripts = Sort-ObjectWithCustomList -InputObject $Scripts -Property BaseName -CustomList $DependencyOrder
        Write-Verbose "Sorting scripts with dependencies [$($Dependencies| Out-String)]"
    }
    $Scripts
}
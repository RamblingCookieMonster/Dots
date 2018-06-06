function Get-DotsScriptHelp {
    <#
    .SYNOPSIS
        Get Dots script help

    .DESCRIPTION
        Get Dots script help

    .PARAMETER Name
        Which Dots script to get help for

        Use file basename.  E.g. ADComputers

    .PARAMETER ScriptsPath
        Path to look for scripts in
        Must include ExternalSources and DotsSources subfolder for -DataSource to work

        If more than one ScriptsPath is specified and duplicate script names are found,
        we pick the first script found

    .PARAMETER Full
        Whether to extract full help

    .EXAMPLE
        Get-DotsScriptHelp ADComputers
        # Show Dots script help for ADComputers

    .EXAMPLE
        Get-DotsScriptHelp ADComputers -ScriptsPath \\Some\Other\Path
        # Show Dots script help for \\Some\Other\Path\ExternalSources\ADComputers.ps1

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding()]
    param(
        [string]$Name,
        [switch]$Full,
        [string[]]$ScriptsPath = $Script:ScriptsPath,
        [bool]$IncludeDotsScripts = $Script:IncludeDotsScripts
    )
    if($IncludeDotsScripts) {
        $ScriptsPath += Join-Path $ModuleRoot Scripts | Select-Object -Unique
    }

    # This bit will ensure one script per base name, with priority based on ScriptsPath
    # (i.e. First name found based on ScriptsPath wins)
    $ScriptsMap = [ordered]@{}
    foreach($Path in $ScriptsPath) {
        $Scripts = Get-ChildItem $ScriptsPath -Recurse -Include *.ps1
        foreach($Script in $Scripts) {
            if($ScriptsMap.Keys -notcontains $Script.BaseName){
                $ScriptsMap.add($Script.BaseName, $Script)
            }
        }
    }
    $Scripts = $ScriptsMap.Values
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
    if($Name) {
        $Scripts = foreach($Script in $Scripts) {
            foreach($BaseName in $Name) {
                if($Script.BaseName -Like $BaseName) {
                    $Script
                    break
                }
            }
        }
        Write-Verbose "Including only -include scripts: $($Scripts.FullName | Out-String)"
    }
    $Params = @{}
    if($Full){
        $Params.add('Full', $Full)
    }
    Get-Help $Scripts @Params
}
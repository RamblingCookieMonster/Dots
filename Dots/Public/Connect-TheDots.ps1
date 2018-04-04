function Connect-TheDots {
[cmdletbinding( SupportsShouldProcess = $True,
                ConfirmImpact='High' )]
    param(
        [validateset('ExternalSources', 'DotsSources')]
        [string]$Scope,
        [string[]]$Include,
        [string[]]$Exclude,
        [hashtable]$Dependencies,
        [switch]$Show
    )
    $RejectAll = $false
    $ConfirmAll = $false
    $Scripts = Get-ChildItem $ScriptsPath -Recurse -Include *.ps1
    Write-Verbose "Found scripts $($Scripts.FullName | Out-String)"
    if($Scope -eq 'ExternalSources') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$ExternalSourcesScriptsPath*"}
        Write-Verbose "Including only ExternalSources scripts: $($Scripts.FullName | Out-String)"
    }
    if($Scope -eq 'DotsSources') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$DotsSourcesScriptsPath*" }
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
    if(Test-Path $SortPath) {
        $Order = Get-Content $SortPath
        if($Order) {
            $Scripts = $Scripts | Sort-CustomList -List $Order -SortOnProperty BaseName
            Write-Verbose "Sorting scripts with order [$Order]"
        }
    }
    if($Dependencies) {
        $DependencyOrder = Get-TopologicalSort $Dependencies
        $Scripts = Sort-ObjectWithCustomList -InputObject $Scripts -Property BaseName -CustomList $DependencyOrder
    }

    Write-Verbose "Running Scripts: $($Scripts.FullName | Out-String)"
    foreach($Script in $Scripts) {
        if ( $PSCmdlet.ShouldProcess( "Connected the dots '$($Script.Fullname)'",
                                      "Connect the dots '$($Script.Fullname)'?",
                                      "Connecting dots" )
        ) {
            try {
                $ConfigScript = Join-Path $ConfPath "$($Script.BaseName).Config.ps1"
                if(Test-Path $ConfigScript) {
                    Write-Verbose "Dot sourcing [$ConfigScript]"
                    . $ConfigScript
                }
                else {
                    Write-Verbose "No config script found at [$ConfigScript]"
                }
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
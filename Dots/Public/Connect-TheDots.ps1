function Connect-TheDots {
    [cmdletbinding()]
    param(
        [validateset('Auto', 'Manual')]
        [string]$Scope,
        [string[]]$Include,
        [string[]]$Exclude,
        [hashtable]$Dependencies
    )
    $Scripts = Get-ChildItem $ScriptsPath -Recurse -Include *.ps1
    Write-Verbose "Found scripts $($Scripts.FullName | Out-String)"
    if($Scope -eq 'Auto') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$AutoPath*"}
        Write-Verbose "Including only auto scripts: $($Scripts.FullName | Out-String)"
    }
    if($Scope -eq 'Manual') {
        $Scripts = $Scripts | Where-Object {$_.FullName -like "$ManualPath*" }
        Write-Verbose "Including only manual scripts: $($Scripts.FullName | Out-String)"
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
    if($Dependencies) {
        $DependencyOrder = Get-TopologicalSort $Dependencies
        $Scripts = Sort-ObjectWithCustomList -InputObject $Scripts -Property BaseName -CustomList $DependencyOrder
    }
    Write-Verbose "Running Scripts: $($Scripts.FullName | Out-String)"

    foreach($Script in $Scripts) {
        try {
            Write-Verbose "Dot sourcing $Script"
            #. $Script -ErrorAction Stop
        }
        catch {
            Write-Error $_
        }
    }
    Write-Verbose "Dots Connected!"
}
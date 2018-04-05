function Get-DotsConfig {
    param(
        [validateset('ScriptsPath', 'ConfPath', 'DataPath')]
        [string[]]$Property = @('ScriptsPath', 'ConfPath', 'DataPath')
    )
    $Output = @{}
    $ConfData = Get-Content $ModuleRoot\dots.conf
    foreach($PathType in $Property) {
        #Check conf data for paths
        $Line = $ConfData | Where-Object {$_ -match "^\s*$PathType\s*=\s*"}
        if($Line){
            $Value = ($Line -split '=')[1].trim()
            $Value = $Value -replace '\$ModuleRoot', $ModuleRoot
            $Value = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)
            $Output.$PathType = $Value
        }
        # Override paths with env vars
        if($Value = (Get-Item ENV:$PathType -ErrorAction SilentlyContinue).Value) {
            $Value = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Value)
            $Output.$PathType = $Value
        }

        # Check for nonexistent paths
        $Path = $Output.$PathType
        if(-not $Path) {
            $Path = Join-Path $ModuleRoot $PathType
            $Output.$PathType = $Path
        }
        if(-not (Test-Path $Path -PathType Container)) {
            throw "The [$PathType] [$Path] does not exist.`nCreate this, or fix it in your [$ModuleRoot\dots.conf]"
        }
    }
    $Output
}
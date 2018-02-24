function Get-ConfigPath {
    [cmdletbinding()]
    param($Path)
    if(-not $Path -or $Path -eq 'Dots') {
        $Name = 'Dots'
    }
    else {
        $Name = (Get-Item $Path).BaseName
    }
    $ExpectedPath = (Resolve-Path "$ConfPath\$Name.Config.ps1" -ErrorAction SilentlyContinue).Path
    if(Test-Path $ExpectedPath) {
        $ExpectedPath
    }
}
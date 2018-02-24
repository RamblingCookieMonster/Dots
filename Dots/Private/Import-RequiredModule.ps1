function Import-RequiredModule {
    [cmdletbinding()]
    param ($Name)
    if(Get-Module $Name -ErrorAction SilentlyContinue) {
        return
    }
    if(Get-Module $Name -ListAvailable -ErrorAction SilentlyContinue) {
        Import-Module $Name -Force
    }
    else {
        Write-Error "Could not load required module [$Name].  Please make sure this is loaded or in a PSModulePath"
    }
}
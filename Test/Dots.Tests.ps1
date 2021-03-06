$PSVersion = $PSVersionTable.PSVersion.Major
$ModuleName = $ENV:BHProjectName
$ModulePath = (Resolve-Path "$PSScriptRoot\..\$ModuleName").Path
# Verbose output for non-master builds on appveyor
# Handy for troubleshooting.
# Splat @Verbose against commands as needed (here or in pester tests)
    $Verbose = @{}
    if($ENV:BHBranchName -notlike "master" -or $env:BHCommitMessage -match "!verbose")
    {
        $Verbose.add("Verbose",$True)
    }

Invoke-PSDepend -Path $ModulePath\.requirements.psd1 -Install -Import -Force -Confirm:$False
Import-Module $ModulePath -Force

#get-command -Module psneo4j | sort Noun | Select -ExpandProperty Name | %{"Describe `"$_ `$PSVersion`" {`n    It 'Should' {`n`n    }`n}`n"}
Describe "$ModuleName PS$PSVersion" {
    It 'Should load' {
        $Module = @( Get-Module $ModuleName )
        $Module.Name -contains $ModuleName | Should be $True
        $Commands = $Module.ExportedCommands.Keys
        $Commands -contains 'Get-DotsConfig' | Should Be $True
        Get-ChildItem $ModulePath\Public | Should -HaveCount $Commands.count
        }
}
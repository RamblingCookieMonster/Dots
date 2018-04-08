# Borrowed from Brandon Olin - Thanks!
function Get-DotsConfigPath {
    <#
    .SYNOPSIS
        Get Dots configuration file path

    .DESCRIPTION
        Get Dots configuration file path

    .EXAMPLE
        Get-DotsConfigPath

    .FUNCTIONALITY
        Dots
    #>
    [CmdletBinding()]
    param()
    end {
        if (Test-IsWindows) {
            Join-Path -Path $env:TEMP -ChildPath "$env:USERNAME-$env:COMPUTERNAME-dots.xml"
        }
        else {
            Join-Path -Path $env:HOME -ChildPath '.dotsconfig' # Leading . and no file extension to be Unixy.
        }
    }
}
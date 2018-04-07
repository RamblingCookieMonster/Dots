# Borrowed from Brandon Olin - Thanks!
function Get-DotsConfigPath {
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
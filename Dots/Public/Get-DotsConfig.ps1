Function Get-DotsConfig {
    <#
    .SYNOPSIS
        Get Dots module configuration

    .DESCRIPTION
        Get Dots module configuration

    .EXAMPLE
        Get-DotsConfig
        # Get config from live module variable

    .EXAMPLE
        Get-DotsConfig -Source Xml
        # Get config from serialized xml

    .PARAMETER Source
        Get the config data from either...

            DotsConfig: the live module variable used for command defaults
            Xml:        the serialized DotsConfig.xml that loads when importing the module

        Defaults to DotsConfig

    .PARAMETER Path
        If specified, read config from this XML file.

        Defaults to DotsConfig.xml in the user temp folder on Windows, or .dotsconfig in the user's home directory on Linux/macOS

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding()]
    param(
        [ValidateSet("DotsConfig","Xml")]
        $Source = "DotsConfig",

        $Path = $script:_DotsConfigXmlPath
    )

    if($Source -eq "DotsConfig" -and -not $PSBoundParameters.ContainsKey('Path')) {
        $Script:DotsConfig
    }
    else {
        Import-Clixml -Path $Path |
            Select-Object -Property $Script:DotsProps
    }
}

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

        Defaults to DotsConfig.xml in the user temp folder on Windows, or .psslack in the user's home directory on Linux/macOS

    .FUNCTIONALITY
        Dots
    #>
    [cmdletbinding(DefaultParameterSetName = 'source')]
    param(
        [parameter(ParameterSetName='source')]
        [ValidateSet("DotsConfig","Xml")]
        $Source = "DotsConfig",

        [parameter(ParameterSetName='path')]
        [parameter(ParameterSetName='source')]
        $Path = $script:_DotsConfigXmlPath
    )

    if($PSCmdlet.ParameterSetName -eq 'source' -and $Source -eq "DotsConfig" -and -not $PSBoundParameters.ContainsKey('Path')) {
        $Script:DotsConfig
    }
    else {
        Import-Clixml -Path $Path |
            Select-Object -Property $Script:DotsProps
    }
}

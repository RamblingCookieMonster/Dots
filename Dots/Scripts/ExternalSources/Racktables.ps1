[cmdletbinding()]
param(
    [string]$Prefix = 'RACK',
    [string]$MergeProperty = 'NameLower',
    [string]$Label = 'Server',
    [string[]]$Properties = @(
        'System'
        'asset',
        'row',
        'rack',
        'height',
        'ru'
    ),
    [string[]]$Excludes = 'puppet_classes',
    [object[]]$Transforms = @(
        '*',
        @{
            label='NameLower'
            expression={
                @($_.System -split " ")[0].ToLower()
            }
        }
    ),
    [string]$BaseUri,
    [string[]]$Domains
)
# Dot source so module import is available in this scope
if($script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    function Get-RackFacts {
        <#
        .SYNOPSIS
            Query RackTables data
        .DESCRIPTION
            Query RackTables data generated via duct tapi:
            http://sjoeboo.github.io/blog/2012/05/31/getting-racktables-location-info-into-puppet/
        .EXAMPLE
            Get-RackFacts -ComputerName cepr*
            # Get all the things that start with cepr
        .EXAMPLE
            Get-RackFacts -ComputerName *
            # Get all the things
        #>
        param (
            [string]$BaseUri,
            [string[]]$ComputerName
        )
        function ConvertFrom-RackFacts {
            [cmdletbinding()]
            param(
                [string]$BaseUri,
                [string]$Name
            )
            $Raw = $null
            $Rows = $null
            $Raw = Invoke-RestMethod -Uri "$BaseUri\$name" -ErrorAction Stop
            if($Raw -is [system.string]) {
                $Rows = $Raw -split "`n"
            }
            if($Rows -and $Rows.count -gt 1) {
                $Output = @{System = [System.Web.HttpUtility]::UrlDecode($Name)}
                foreach($Row in $Rows) {
                    if($Row -match ":") {
                        $SplitRow = @($Row -split ":")
                        $Key = $SplitRow[0]
                        $Count = $SplitRow.count
                        $Value = $SplitRow[1..$Count] -join ":"
                        if($Value -is [system.string]){$Value = $Value.trim()}
                        if($key -is [system.string]){$key = $key.trim()}
                        $Output.add($Key, $Value)
                    }
                }
                [pscustomobject]$Output
            }
        }

        foreach($Name in $ComputerName) {
            # this isn't a real API, it's duct tape from a blog post - handy, but... we'll do the work.
            $SearchAll = $False
            $Wildcard = $False
            if($Name -match '\*') {
                $SearchAll = $True
                $WildCard = $True
            }
            try {
                ConvertFrom-RackFacts -BaseUri $BaseUri -Name $Name -ErrorAction Stop
            }
            catch {
                if($_.Exception.Message -match '404') {
                    $SearchAll = $True
                }
                else {
                    Write-Error $_
                }
            }

            if($SearchAll) {
                if(-not $Wildcard) {
                    $Name = "*$Name*"
                }
                $d = Invoke-WebRequest $BaseUri
                $MatchingLinks = $d.links.where({$_.href -notmatch "^\?|^/rack" -and $_.href -like $Name})
                foreach($Link in $MatchingLinks) {
                    ConvertFrom-RackFacts -BaseUri $BaseUri -Name $Link.href
                }
            }
        }
    }
}

$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date

$Nodes = Get-RackFacts -BaseUri $BaseUri -ComputerName *
$Nodes = $Nodes |
        Select-Object -Property $Properties |
        Select-Object -Property $Transforms

$names = $nodes.NameLower
$NameHash = @{}
$Dupes = foreach($Name in $Names) {
    if(-not $NameHash.ContainsKey($Name)){
        $NameHash.Add($Name,$null)
    }
    else {
        $Name
    }
}

$Nodes = Foreach($Node in $Nodes.where({$Dupes -notcontains $_.NameLower})) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${script:CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    foreach($Domain in $Domains) {
        # Update existing, do not create new nodes, data is garbage
        Set-Neo4jNode -Label $Label -Hash @{$script:ServerUnique = "$($Node.$Unique).$Domain"} -InputObject $Node -NoCreate
    }
}

<#
.SYNOPSIS
    Pull Computer accounts from Active Directory, add to Neo4j

.DESCRIPTION
    Pull Computer accounts from Active Directory, add to Neo4j

    This is invoked by Connect-TheDots

.PARAMETER Prefix
    Prefix to append to properties when we add them to Neo4j

    This helps identify properties that might come from mutiple sources, or where the source is ambiguous

    For example, Description becomes ADDescription

    Defaults to AD.  Change at your own risk

.PARAMETER MergeProperty
    We use this to correlate Server data from multiple sources

    We assume server data should correlate if the value for this on an AD Computer matches the ServerUnique value in Neo4j

    Default: DNSHostname

.PARAMETER Label
    What label do we assign the data we pull?

    Defaults to Server.  Change at your own risk

.PARAMETER Properties
    Properties to extract and select from AD

.PARAMETER Excludes
    Properties to exclude (in line with transforms)

.PARAMETER Transforms
    Properties to select again (in line with excludes)

    Example:

    *, # Keep all properties from -Properties
    @{
        label = 'ParentCanonicalName'
        expression = {$_.CanonicalName -replace "/$($_.Name)$"}
    }

    This would keep all properties from -Properties, and add a calculated ParentCanonicalName

.PARAMETER ExcludeOlderThanMonths
    Exclude AD Computers with lastLogonTimestamp older than this many months

    Default: 12

.FUNCTIONALITY
    Dots
#>
[cmdletbinding()]
param(
    [string]$Prefix = 'AD',
    [string]$MergeProperty = 'DNSHostname',
    [string]$Label = 'Server',
    [string[]]$Properties = @(
        'CanonicalName',
        'Description',
        'IPv4Address',
        'LastLogonDate',
        'OperatingSystem',
        'OperatingSystemVersion',
        'DNSHostname',
        'Name'
    ),
    [string[]]$Excludes = @('Name'),
    [object[]]$Transforms = @(
        '*',
        @{
            label = 'ParentCanonicalName'
            expression = {$_.CanonicalName -replace "/$($_.Name)$"}
        },
        @{
            label = "NameLower"
            expression = {$_.Name.tolower()}
        }
    ),
    [int]$ExcludeOlderThanMonths = 12,
    [switch]$AllLower = $Script:AllLower
)
$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date
$CruftDate = $Date.AddYears(-$ExcludeOlderThanMonths)
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    . Import-RequiredModule ActiveDirectory -ErrorAction Stop
}

$Nodes = Get-ADComputer -Filter * -Properties $Properties |
    Where-Object {$_.DNSHostname -and $_.LastLogonDate -gt $CruftDate} |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Nodes = Foreach($Node in $Nodes) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${script:CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    if($AllLower) {
        ConvertTo-Lower -InputObject $Output    
    }
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique) computers" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$script:ServerUnique = ($Node.$Unique).ToLower()} -InputObject $Node
}

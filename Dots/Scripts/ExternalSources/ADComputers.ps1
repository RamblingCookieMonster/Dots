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
    [int]$ExcludeOlderThanMonths = 12
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
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique) computers" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$script:ServerUnique = ($Node.$Unique).ToLower()} -InputObject $Node
}

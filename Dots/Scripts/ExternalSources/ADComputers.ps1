[cmdletbinding()]
param(
    [string]$Prefix = 'AD',
    [string]$MergeProperty = 'DNSHostName',
    [string]$Label = 'Server',
    [string[]]$Properties = @(
        'CanonicalName',
        'Description',
        'IPv4Address',
        'LastLogonDate',
        'OperatingSystem',
        'OperatingSystemVersion',
        'DNSHostName',
        'Name'
    ),
    [string[]]$Excludes = @('Name'),
    [object[]]$Transforms
)
# Dot source so module import is available in this scope
if($TestMode) {
    . $(Join-Path $DataPath Mocks.ps1)
}
else {
    . Import-RequiredModule ActiveDirectory -ErrorAction Stop
}

# Resolve Dots config, script config, override with parameters if defined
$ConfigPath = Get-ConfigPath Dots
if($ConfigPath) {
    . $ConfigPath
}
$ConfigPath = Get-ConfigPath $PSCommandPath
if($ConfigPath) {
    . $ConfigPath
}
$PSBoundParameters.Keys | ForEach-Object {
    if($PSBoundParameters.ContainsKey($_)) {
        Set-Variable -Name $_ -Value $PSBoundParameters[$_] -Force
    }
    Write-Verbose "$_ is $(Get-Variable -Name $_ -ValueOnly | Out-String)"
}

$Nodes = Get-ADComputer -Filter * -Properties $Properties |
    Where-Object {$_.DNSHostName -and $_.LastLogonDate -gt $CruftDate} |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Nodes = Foreach($Node in $Nodes) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique) computers" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$ServerUnique = ($Node.$Unique).ToLower()} -InputObject $Node
}

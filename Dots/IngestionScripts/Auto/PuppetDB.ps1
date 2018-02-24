[cmdletbinding()]
param(
    [string]$Prefix = 'PDB',
    [string]$MergeProperty = 'NameLower',
    [string]$Label = 'Server',
    [string[]]$Properties = @(
        'ipaddress',
        'osfamily',
        'environment',
        'vlan',
        'uptime',
        'serialnumber',
        'location_row',
        'kernelrelease',
        'group',
        'puppet_classes'
    ),
    [switch]$NoCreate,
    [string[]]$Excludes,
    [object[]]$Transforms,
    [string]$Unique
)
# Dot source so module import is available in this scope
. Import-RequiredModule PSPuppetDB -ErrorAction Stop

# Resolve Dots config, script config, override with parameters if defined
$ConfigPath = Get-ConfigPath Dots
if($ConfigPath) {
    . $ConfigPath
}
$ConfigPath = Get-ConfigPath $PSCommandPath
if($ConfigPath) {
    . $ConfigPath
}
'Excludes', 'Transforms', 'Unique' | ForEach-Object {
    if($PSBoundParameters.ContainsKey($_)) {
        Set-Variable -Name $_ -Value $PSBoundParameters[$_] -Force
    }
    Write-Verbose "$_ is $(Get-Variable -Name $_ -ValueOnly | Out-String)"
}

$Nodes = Get-PDBNode

$TotalCount = $Nodes.count
$Count = 0
$Nodes = foreach($Node in $Nodes) {
    Write-Progress -Activity "Getting Puppet info" -Status  "Getting $($Node.Name)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Get-PDBNodeFact -Node $Node.Name |
        Select -Property $Properties |
        Select -Property $Transforms |
        Select -Property * -ExcludeProperty $Excludes
}

$Nodes = Foreach($Node in $Nodes) {
    Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Node -MemberType NoteProperty -Name "${CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$ServerUnique = $Node.$Unique} -InputObject $Node
}








$Nodes = Foreach($Node in $Nodes) {
    Add-PropertyPrefix -Prefix $Prefix -Object $Node
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$Unique)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$ServerUnique = ($Node.$Unique).ToLower()} -InputObject $Node
}

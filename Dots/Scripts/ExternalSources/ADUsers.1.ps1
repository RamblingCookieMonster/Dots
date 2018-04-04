[cmdletbinding()]
param(
    [string]$Prefix = 'AD',
    [string]$MergeProperty = 'SID',
    [string]$Label = 'User',
    [string[]]$Properties = @(
        'SamAccountName',
        'CN',
        'CanonicalName',
        'DisplayName',
        'Company',
        'Department',
        'Title',
        'givenName',
        'surname',
        'mail',
        'uidNumber',
        'gidNumber',
        'SID',
        'LastLogonDate'
    ),
    [string[]]$Excludes = @('CanonicalName', 'CN'),
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

$Nodes = Get-ADUser -Filter 'enabled -eq $true' -Properties $Properties |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Nodes = Foreach($Node in $Nodes) {
    $Node.SID = $Node.SID.Value
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$MergeProperty) users" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$Unique = $Node.$Unique} -InputObject $Node
}
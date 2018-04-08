[cmdletbinding()]
param(
    [string]$Prefix = 'AD',
    [string]$MergeProperty = 'SID',
    [string]$Label = 'Group',
    [string[]]$Properties = @(
        'SamAccountName',
        'CN',
        'CanonicalName',
        'Name',
        'gidNumber',
        'SID',
        'ManagedBy',
        'Description'
    ),
    [string[]]$Excludes = @('CanonicalName', 'CN', 'ManagedBy'),
    [object[]]$Transforms = @(
        '*',
        @{
            label = 'ParentCanonicalName'
            expression = {$_.CanonicalName -replace "/$($_.CN)$"}
        },
        @{
            label = "Managed_By"
            expression = {
                try {
                    if($_.ManagedBy) {
                        $a = $null
                        $a = $_
                        (ActiveDirectory\Get-ADObject $_.ManagedBy -Properties SamAccountName -ErrorAction Stop).SamAccountName
                    }
                }
                catch {Write-Warning "$($a.Name) managed by doesn't exist:$($a.ManagedBy)"}}
        }
    )
)
$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    . Import-RequiredModule ActiveDirectory -ErrorAction Stop
}

$Nodes = Get-ADGroup -Filter * -Properties $Properties |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Nodes = Foreach($Node in $Nodes) {
    $Node.SID = $Node.SID.Value
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${script:CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$MergeProperty) users" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$Unique = $Node.$Unique} -InputObject $Node
}
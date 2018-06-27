<#
.SYNOPSIS
    Pull groups from Active Directory, add to Neo4j

.DESCRIPTION
    Pull groups from Active Directory, add to Neo4j

    This is invoked by Connect-TheDots

.PARAMETER Prefix
    Prefix to append to properties when we add them to Neo4j

    This helps identify properties that might come from mutiple sources, or where the source is ambiguous

    For example, Description becomes ADDescription

    Defaults to AD.  Change at your own risk

.PARAMETER MergeProperty
    We use this to correlate with existing AD group data in Neo4j

    Default: SID

.PARAMETER Label
    What label do we assign the data we pull?

    Defaults to Group.  Change at your own risk

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

.FUNCTIONALITY
    Dots
#>
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
    ),
    [switch]$AllLower = $Script:AllLower
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
    if($AllLower) {
        ConvertTo-Lower -InputObject $Output -Exclude SID   
    }
    $Output
}

$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $($Node.$MergeProperty) users" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$Unique = $Node.$Unique} -InputObject $Node
}
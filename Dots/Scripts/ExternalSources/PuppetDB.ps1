<#
.SYNOPSIS
    Pull nodes and facts from PuppetDB, add to Neo4j

.DESCRIPTION
    Pull nodes and facts from PuppetDB, add to Neo4j

    Uses PSPuppetDB from the PowerShell Gallery

    This is invoked by Connect-TheDots

.PARAMETER Prefix
    Prefix to append to properties when we add them to Neo4j

    This helps identify properties that might come from mutiple sources, or where the source is ambiguous

    For example, environment becomes PDBenvironment

    Defaults to PDB.  Change at your own risk

.PARAMETER MergeProperty
    We use this to correlate Server data from multiple sources

    We assume server data should correlate if the value for this on a Puppet node matches the ServerUnique value in Neo4j

    Default: NameLower

.PARAMETER Label
    What label do we assign the data we pull?

    Defaults to Server.  Change at your own risk

.PARAMETER Properties
    Properties (facts) to extract and select from PuppetDB

.PARAMETER Excludes
    Properties (facts) to exclude (in line with transforms)

.PARAMETER Transforms
    Properties (facts) to select again (in line with excludes)

    Example:

    *, # Keep all properties from -Properties
    @{
        label='NameLower'
        expression={$Node.certname.ToLower()}
    }

    This would keep all properties from -Properties, and add a calculated NameLower

.PARAMETER ExcludeOlderThanMonths
    Exclude AD Computers with lastLogonTimestamp older than this many months

    Default: 12

.FUNCTIONALITY
    Dots
#>
[cmdletbinding()]
param(
    [string]$Prefix = 'PDB',
    [string]$MergeProperty = 'NameLower',
    [string]$Label = 'Server',
    [string[]]$Properties = @(
        'certname',
        'ipaddress',
        'osfamily',
        'environment',
        'vlan',
        'uptime',
        'serialnumber',
        'location_row',
        'kernelrelease',
        'group',
        'puppet_classes',
        'manufacturer',
        'productname',
        'memorysize_mb',
        'puppetversion'
    ),
    [string[]]$Excludes = 'puppet_classes',
    [object[]]$Transforms = @(
        '*',
        @{
            label='NameLower'
            expression={$Node.certname.ToLower()}
        },
        @{
            label='Classes'
            expression={
                $Classes = $null
                if($_.puppet_classes -match "^\[.*\]$") {
                    $Classes = $_.puppet_classes.trimstart('[').trimend(']') -split "," | where {$_}
                    $Classes = @(
                        foreach($Class in $Classes) {
                            $Class.trim(' ').trim('"')
                        }
                    )
                }
                $Classes | Sort -Unique
            }
        },
        @{
            label='FactsTimestamp'
            expression={
                try{
                    Get-Date $node.'facts-timestamp'
                }
                catch {
                    $node.'facts-timestamp'
                }
            }
        },
        @{
            label='ReportTimestamp'
            expression={
                try{
                    Get-Date $node.'report-timestamp'
                }
                catch {
                    $node.'report-timestamp'
                }
            }
        }
    ),
    [switch]$AllLower = $Script:AllLower
)
# Dot source so module import is available in this scope
if($script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    . Import-RequiredModule PSPuppetDB -ErrorAction Stop
}
Write-Verbose "Querying for all puppet nodes"
$Date = Get-Date
$Nodes = Get-PDBNode

$TotalCount = $Nodes.count
$Count = 0
Write-Verbose "Adding or updating $TotalCount nodes from Puppet data"

$Nodes = foreach($Node in $Nodes) {
    Write-Progress -Activity "Getting Puppet info" -Status  "Getting $($Node.Name)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Get-PDBNodeFact -CertName $Node.certname |
        Select-Object -Property $Properties |
        Select-Object -Property $Transforms |
        Select-Object -Property * -ExcludeProperty $Excludes
}
$Nodes = Foreach($Node in $Nodes) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Node
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${script:CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    if($AllLower) {
        ConvertTo-Lower -InputObject $Output    
    }
    $Output
}

$Unique = "${Prefix}${MergeProperty}"
$TotalCount = $Nodes.count
$Count = 0
Foreach($Node in $Nodes) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding $( $Node.$Unique )" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -Label $Label -Hash @{$script:ServerUnique = $Node.$Unique} -InputObject $Node
}

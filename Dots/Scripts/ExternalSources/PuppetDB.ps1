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
        'puppet_classes'
    ),
    [string[]]$Excludes = 'puppet_classes',
    [object[]]$Transforms = @(
        '*',
        @{
            label = "UpdateDate"
            expression = {$Date}
        },
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
        }
    )
)
# Dot source so module import is available in this scope
if($script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    . Import-RequiredModule PSPuppetDB -ErrorAction Stop
}

$Nodes = Get-PDBNode

$TotalCount = $Nodes.count
$Count = 0
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

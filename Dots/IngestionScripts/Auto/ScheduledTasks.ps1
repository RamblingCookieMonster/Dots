[cmdletbinding()]
param(
    [string]$Prefix = 'TSK',
    [string]$Label = 'Task',
    [string[]]$Properties = @(
        'ComputerName',
        'Name',
        'Path',
        'Enabled',
        'Action',
        'Arguments',
        'UserId',
        'LastRunTime',
        'NextRunTime',
        'Status',
        'Author',
        'RunLevel',
        'Description'
    ),
    [string[]]$Excludes,
    [object[]]$Transforms
)
# Dot source so module import is available in this scope
if($TestMode) {
    . $(Join-Path $DataPath Mocks.ps1)
}
<#
    Import or define code to get all scheduled tasks
    Consider:
        local scripts that push to a limited access share (domain computers create, creator owner fullish), read from there
        delegated/constrained endpoints that avoid exposing creds to mimikatz
        other options that don't give the remote systems your creds...
#>

# Resolve Dots config, script config, override with parameters if defined
$ConfigPath = Get-ConfigPath Dots
if($ConfigPath) {
    . $ConfigPath
}
$ConfigPath = Get-ConfigPath $PSCommandPath
if($ConfigPath) {
    . $ConfigPath
}
'Excludes', 'Transforms' | ForEach-Object {
    if($PSBoundParameters.ContainsKey($_)) {
        Set-Variable -Name $_ -Value $PSBoundParameters[$_] -Force
    }
    Write-Verbose "$_ is $(Get-Variable -Name $_ -ValueOnly | Out-String)"
}

$Tasks = Get-ScheduledTasks |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Tasks = Foreach($Task in $Tasks) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Task
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Tasks.count
$Count = 0
Foreach($Task in $Tasks) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding task $($Task.$MergeProperty)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Set-Neo4jNode -InputObject $Task -Label $Label -Hash @{
        TSKHostName = $Task.TSKHostName
        TSKPath = $Task.TSKPath
    }

    # hostname's not unique across all qualified doman namespaces?  Use different logic
    New-Neo4jRelationship -LeftQuery "MATCH (left:Task)
                                      WHERE left.TSKHostName = {TSKHostName} AND
                                            left.TSKPath = {TSKPath}" `
                          -RightQuery "MATCH (right:Server)
                          WHERE right.{$CMDBPrefix}HostName =~ {TSKHostName} AND
                                left.TSKPath = {TSKPath}" `
                          -Parameters `
                          -Properties `
                          -Type RunsOn

}


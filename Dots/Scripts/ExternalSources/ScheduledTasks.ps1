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
    [string[]]$Excludes = 'Path',
    [object[]]$Transforms = @(
        '*',
        @{
            label = 'TaskPath'
            expression = {
                $_.Path -replace "^/"
            }
        },
        @{
            label = 'Hostname'
            expression = {
                $_.ComputerName.ToLower()
            }
        }
    )
)
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    . $(Join-Path $Script:DataPath Mocks.ps1)
}
<#
    Import or define code to get all scheduled tasks
    Consider:
        local scripts that push to a limited access share (domain computers create, creator owner fullish), read from there
        delegated/constrained endpoints that avoid exposing creds to mimikatz
        other options that don't give the remote systems your creds...
#>

[object[]]$Tasks = Get-ScheduledTasks |
    Select-Object -Property $Properties |
    Select-Object -Property $Transforms -ExcludeProperty $Excludes

$Tasks = Foreach($Task in $Tasks) {
    $Output = Add-PropertyPrefix -Prefix $Prefix -Object $Task
    Add-Member -InputObject $Output -MemberType NoteProperty -Name "${Script:CMDBPrefix}${Prefix}UpdateDate" -Value $Date -Force
    $Output
}

$TotalCount = $Tasks.count
$Count = 0
Foreach($Task in $Tasks) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Adding task $($Task.$MergeProperty)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++

    Set-Neo4jNode -InputObject $Task -Label $Label -Hash @{
        TSKHostname = $Task.TSKHostname
        TSKTaskPath = $Task.TSKTaskPath
    }

    # hostname's not unique across all qualified doman namespaces?  Use different logic
    New-Neo4jRelationship -LeftQuery "MATCH (left:Task)
                                      WHERE left.TSKHostname = {TSKHostname} AND
                                            left.TSKTaskPath = {TSKTaskPath}" `
                          -RightQuery "MATCH (right:Server)
                          WHERE right.${script:CMDBPrefix}Hostname STARTS WITH {Start}" `
                          -Parameters  @{
                              TSKHostname = $Task.TSKHostname
                              TSKTaskPath = $Task.TSKTaskPath
                              Start = "$($Task.TSKHostname)." # Assumes host names are unique across all domains
                          } `
                          -Type RunsOn

}


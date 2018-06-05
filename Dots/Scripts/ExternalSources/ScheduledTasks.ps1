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
    [object[]]$Transforms = @(
        '*',
        @{
            label = 'Hostname'
            expression = {
                $_.ComputerName.ToLower()
            }
        }
    ),
    [string]$DataPath
)
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
<#
    Import or define code to get all scheduled tasks
    Consider:
        * local scripts that push to a limited access share (domain computers create, creator owner fullish), read from there
        * delegated/constrained endpoints that avoid exposing creds to mimikatz
        * other options that don't give the remote systems your creds...
#>

$Files = Get-ChildItem $DataPath
$Tasks = foreach($File in $Files){
    Import-Clixml $File |
        Where-Object {$_.ComputerName -and $_.Path -and $_.Action} |
        Select-Object -Property $Properties |
        Select-Object -Property $Transforms -ExcludeProperty $Excludes
}

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
        TSKPath = $Task.TSKPath
    }

    # hostname's not unique across all qualified doman namespaces?  Use different logic
    New-Neo4jRelationship -LeftQuery "MATCH (left:Task)
                                      WHERE left.TSKHostname = {TSKHostname} AND
                                            left.TSKPath = {TSKPath}" `
                          -RightQuery "MATCH (right:Server)
                          WHERE right.${script:CMDBPrefix}Hostname STARTS WITH {Start}" `
                          -Parameters  @{
                              TSKHostname = $Task.TSKHostname
                              TSKPath = $Task.TSKPath
                              Start = "$($Task.TSKHostname)." # Assumes host names are unique across all domains
                          } `
                          -Type RunsOn
}


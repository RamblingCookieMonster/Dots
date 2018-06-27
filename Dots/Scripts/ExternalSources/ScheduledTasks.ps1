<#
.SYNOPSIS
    Pull serialized Scheduled Tasks data, add to Neo4j

.DESCRIPTION
    Pull serialized Scheduled Tasks data, add to Neo4j

    * Assumes properties line up with Get-ScheduledTasks from the WFTools module in the PowerShell Gallery
    * Assumes data is serialized via Export-CliXml to one or more paths

    This is quite opinionated.  We prefer this route to directly connecting to nodes.  An example implementation:
    * A central limited access share accessible by all computers.  Perhaps domain computers create, creator owner fullish
    * GPO creates scheduled task on all computers
    * Scheduled task collects scheduled tasks from the local computer, exports clixml to limited access share

    This is invoked by Connect-TheDots

.PARAMETER Prefix
    Prefix to append to properties when we add them to Neo4j

    This helps identify properties that might come from mutiple sources, or where the source is ambiguous

    For example, Description becomes TSKDescription

    Defaults to TSK.  Change at your own risk

.PARAMETER Label
    What label do we assign the data we pull?

    Defaults to Task.  Change at your own risk

.PARAMETER Properties
    Properties to extract and select from scheduled task data

.PARAMETER Excludes
    Properties to exclude (in line with transforms)

.PARAMETER Transforms
    Properties to select again (in line with excludes)

    Example:

        '*',
        @{
            label = 'Hostname'
            expression = {
                $_.ComputerName.ToLower()
            }
        }

    This would keep all properties from -Properties, and add a calculated Hostname

.PARAMETER DataPath
    One or more paths to data holding clixml for scheduled tasks.  Maps to Get-ChildItem Path (i.e. -Path $DataPath)

    For example:
    '\\Path\To\Share\task_*.xml'
    '\\Path\To\Share\tasks\*.xml'

.FUNCTIONALITY
    Dots
#>
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
    [string[]]$DataPath,
    [switch]$AllLower = $Script:AllLower
)
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}

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
    if($AllLower) {
        ConvertTo-Lower -InputObject $Output    
    }
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


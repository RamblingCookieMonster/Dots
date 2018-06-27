<#
.SYNOPSIS
    Pull serialized local group membership data, add to Neo4j

.DESCRIPTION
    Pull serialized local group membership data, add to Neo4j

    This creates relationships between AD users/groups and Servers

    * Assumes properties line up with output from https://github.com/proxb/PowerShell_Scripts/blob/master/Get-LocalGroupMembership.ps1
    * Assumes data is serialized via Export-CliXml to one or more paths

    This is quite opinionated.  We prefer this route to directly connecting to nodes.  An example implementation:
    * A central limited access share accessible by all computers.  Perhaps domain computers create, creator owner fullish
    * GPO creates scheduled task on all computers
    * Scheduled task collects local group memberships, exports clixml to limited access share

    This is invoked by Connect-TheDots

.PARAMETER Prefix
    Prefix to append to properties when we add them to Neo4j

    This helps identify properties that might come from mutiple sources, or where the source is ambiguous

    This is only used for an update date (e.g. DotsGRPMBRUpdateDate)

    Defaults to GRPMBR

.PARAMETER DataPath
    One or more paths to data holding clixml for scheduled tasks.  Maps to Get-ChildItem Path (i.e. -Path $DataPath)

    For example:
    '\\Path\To\Share\task_*.xml'
    '\\Path\To\Share\tasks\*.xml'

.PARAMETER Domains
    Append these to correlate current hostname to Neo4j Server nodes which are fully qualified

    E.g. if Computername is dc01, and Domains is contoso.com and contoso2.com,
         we create relationships to servers with hostname dc01.contoso.com and/or dc01.contoso2.com

.FUNCTIONALITY
    Dots
#>
[cmdletbinding()]
param(
    [string]$Prefix = 'GRPMBR',
    [string[]]$DataPath,
    [string]$Domains,
    [switch]$AllLower = $Script:AllLower
)
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}

$Files = Get-ChildItem $DataPath
$GroupMembers = foreach($File in $Files){
    Import-Clixml $File |
        Where-Object {$_.Name -and $_.ComputerName -and $_.Type -and $_.ParentGroup -and $_.LocalGroup}
}

$GroupMap = @{
    Administrators ='IsInAdministrators'
    'Remote Desktop Users' = 'IsInRemoteDesktopUsers'
}

foreach($GroupMember in $GroupMembers){
    # Create local users - LOW PRIORITY
    # Relationships
    if($GroupMember.Type -eq 'Domain') {
        if($GroupMember.isGroup){
            $LeftLabel = 'Group'
        }
        else {
            $LeftLabel = 'User'
        }
        $LocalGroup = $GroupMember.LocalGroup
        $RelationshipType = $GroupMap.$LocalGroup
        if($AllLower) {
            ConvertTo-Lower -InputObject $GroupMember    
        }
        $Properties = @{
            "${Script:CMDBPrefix}${Prefix}UpdateDate" = $Date
            Depth = $GroupMember.Depth
            ParentGroup = $GroupMember.ParentGroup
        }
        if(-not $RelationshipType) {
            continue
        }
        $Params = @{
            Type = $RelationshipType
            LeftLabel = $LeftLabel
            LeftHash = @{ADSamAccountName = $GroupMember.Name}
            RightLabel = 'Server'
            Properties = $Properties
        }
        foreach($Domain in $Domains) {
            New-Neo4jRelationship @Params -RightHash @{$script:ServerUnique = "$($GroupMember.Computername.tolower()).$Domain"}
        }
    }
}

[cmdletbinding()]
param(
    [string]$Prefix = 'GRPMBR',
    [string[]]$DataPath,
    [string]$Domains
)
$Date = Get-Date
# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
<#
    Consider:
        * local scripts that push to a limited access share (domain computers create, creator owner fullish), read from there
        * delegated/constrained endpoints that avoid exposing creds to mimikatz
        * other options that don't give the remote systems your creds...
#>

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

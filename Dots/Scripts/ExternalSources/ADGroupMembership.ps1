[cmdletbinding()]
param(
)

# Dot source so module import is available in this scope
if($Script:TestMode) {
    Write-Verbose "Using mock functions from $ModuleRoot/Mock/Mocks.ps1"
    . "$ModuleRoot/Mock/Mocks.ps1"
}
else {
    . Import-RequiredModule ActiveDirectory -ErrorAction Stop
}

$Groups = Get-ADGroup -Properties ManagedBy, MemberOf -Filter * | Select-Object DistinguishedName, SID, Name, ManagedBy, MemberOf
$Users = Get-ADUser -Properties MemberOf -Filter 'enabled -eq $true' | Select-Object DistinguishedName, SID, MemberOf
$SIDMap = @{}
$TypeMap = @{}
foreach($Group in $Groups){
    $SIDMap.Add($Group.DistinguishedName, $Group.SID.Value)
    $TypeMap.Add($Group.DistinguishedName, 'Group')
}
foreach($User in $Users){
    $SIDMap.Add($User.DistinguishedName, $User.SID.Value)
    $TypeMap.Add($User.DistinguishedName, 'User')
}
$GroupUserMemberMap = @{}
foreach($User in $Users) {
    $UserSID = $User.SID.Value
    foreach($Group in $User.MemberOf) {
        $GroupSID = $SIDMap[$Group]
        if(-not $GroupUserMemberMap.ContainsKey($GroupSID)) {
            $GroupUserMemberMap.Add($GroupSID, $(New-Object System.Collections.ArrayList ))
            [void]$GroupUserMemberMap[$GroupSID].Add($UserSID)
        }
        else {
            [void]$GroupUserMemberMap[$GroupSID].Add($UserSid)
        }
    }
}

$GroupGroupMemberMap = @{}
foreach($Member in $Groups) {
    $MemberSID = $Member.SID.Value
    foreach($Group in $Member.MemberOf) {
        $GroupSID = $SIDMap[$Group]
        if(-not $GroupGroupMemberMap.ContainsKey($GroupSID)) {
            $GroupGroupMemberMap.Add($GroupSID, $(New-Object System.Collections.ArrayList ))
            [void]$GroupGroupMemberMap[$GroupSID].Add($MemberSID)
        }
        else {
            [void]$GroupGroupMemberMap[$GroupSID].Add($MemberSID)
        }
    }
}

Invoke-Neo4jQuery -Query "MATCH ()-[r:MemberOf]->() DELETE r"


$TotalCount = $GroupUserMemberMap.count
$Count = 0
Foreach($Group in $GroupUserMemberMap.Keys) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Relating memberof for group $($Group.SID)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Invoke-Neo4jQuery -Query "
        MATCH (g:Group {ADSID: {group}})
        MATCH (a:User) WHERE a.ADSID IN {members}
        CREATE (a)-[:MemberOf]->(g)
    " -Parameters @{
        group = $Group
        members = $GroupUserMemberMap[$Group]
    }
}

$TotalCount = $GroupGroupMemberMap.count
$Count = 0
Foreach($Group in $GroupGroupMemberMap.Keys) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Relating memberof for group $($Group.SID)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    Invoke-Neo4jQuery -Query "
        MATCH (g:Group {ADSID: {group}})
        MATCH (a:Group) WHERE a.ADSID IN {members}
        CREATE (a)-[:MemberOf]->(g)
    " -Parameters @{
        group = $Group
        members = $GroupGroupMemberMap[$Group]
    }
}

Invoke-Neo4jQuery -Query "MATCH ()-[r:ManagedBy]->() DELETE r"
# Managedby for groups
$TotalCount = $Groups.count
$Count = 0
Foreach($Group in $Groups.where({$_.ManagedBy -and $SIDMap.ContainsKey( $_.managedby ) -and $TypeMap.ContainsKey($_.managedby)})) {
    Write-Progress -Activity "Updating Neo4j" -Status  "Relating managedby for group $($Group.SID.value)" -PercentComplete (($Count / $TotalCount)*100)
    $Count++
    $SID = $null
    $SID = $SIDMap[$Group.ManagedBy]
    if($SID){
        New-Neo4jRelationship -LeftLabel Group -LeftHash @{ADSID = $Group.SID.Value} -RightLabel $TypeMap[$Group.ManagedBy] -RightHash @{ADSID = $SID} -Type ManagedBy
    }
}

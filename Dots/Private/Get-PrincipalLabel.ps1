# Check neo4j, should not need AD (if not defined in neo4j, your relationship creation fails anyhow)
# Case sensitive, so be consistent with propery mappings...  We'll create and use indexes (case insensitive IIRC down the road if warranted)
function Get-PrincipalLabel {
    [cmdletbinding()]
    param($Name)
    $Account = $null
    $Query = "MATCH (n) WHERE n.ADSamAccountName = {Name} RETURN labels(n)"
    $Account = Invoke-Neo4jQuery -Query $Query -Parameters @{Name = $Name} -as Row
    if($o = $Account -match 'User')   { $o }
    if($o = $Account -match 'Group')  { $o }
    if($o = $Account -match 'Server') { $o }
}
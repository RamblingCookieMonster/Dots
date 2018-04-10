# Cypher is a
    # declarative,
    # SQL-inspired language
# for describing patterns in graphs
# visually using an ascii-art syntax

# https://neo4j.com/developer/cypher-query-language/
# https://neo4j.com/docs/cypher-refcard/current/
# https://neo4j.com/developer/guide-sql-to-cypher/ Northwind Relational DB to Neo4j
# https://neo4j.com/docs/developer-manual/current/cypher/
# Many other hand references


<#
Nodes and relationships

()                  Nodes
(:Server)           All nodes labeled server
(s:Server)          $s = All nodes labeled server

[]                  Relationships
[r:DependsOn]->(s)  $r = Any relationship with a DependsOn type.
                    $s = any node with a dependency

#>

# We pre-populated Dots, more on that later
# We'll run some Cypher queries with PSNeo4j
Import-Module PSNeo4j -Force

# Set initial password and psneo4j config
$Password = ConvertTo-SecureString -String "some secure password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $Password
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://192.168.99.100:7474' # 'http://127.0.0.1:7474'

# all nodes
Invoke-Neo4jQuery -Query @"
MATCH (n)
RETURN n
"@

# all server dependson service nodes and relationships
Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN s,r,svc
"@ | Format-List -Force

# Examples building different output
Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN s.DotsHostname AS ComputerName,
       type(r) AS Relationship,
       svc.name AS ServiceName
"@ -As ParsedColumns | Format-Table -AutoSize

Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN {
    ServiceName: svc.name,
    Servers: collect(s.DotsHostname)
}
"@ -As Row

# Browse?
# http://192.168.99.100:7474/browser/

# Clean up
Invoke-Neo4jQuery -Query @"
MATCH (n)
DETACH DELETE n
"@


Clear-Neo4j # Does the same, also kills indexes and constraints

code ./Demo/2-psneo4j.ps1
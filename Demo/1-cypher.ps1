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

Clear-Neo4j

Invoke-Neo4jQuery -Query @"
MATCH (n)
RETURN n
"@

# We want unique node names
New-Neo4jConstraint -Label Server -Property name -Unique
Get-Neo4jConstraint

# Create nodes
Invoke-Neo4jQuery -Query @"
CREATE (n:Server { name: 'dc01'})
RETURN n
"@
Invoke-Neo4jQuery -Query @"
CREATE (n:Server { name: {name} })
RETURN n
"@ -Parameters @{name = 'dc02'} #Parameterize queries

Invoke-Neo4jQuery -Query @"
CREATE (n:Service { name: {name} })
RETURN n
"@ -Parameters @{name = 'Active Directory'}

# Create relationships
Invoke-Neo4jQuery -Query @"
MATCH (s:Server), (svc:Service)
WHERE s.name =~ 'dc.*' AND
      svc.name = 'Active Directory'
CREATE (s)-[r:IsPartOf { load_balanced: true }]->(svc)
RETURN r
"@

# Query
# all nodes:
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
RETURN s.name AS ServerName,
       type(r) AS Relationship,
       svc.name AS ServiceName
"@ -As ParsedColumns | Format-List -Force

Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN {
    ServiceName: svc.name,
    Servers: collect(s.name)
}
"@ -as Row


# Clean up
Invoke-Neo4jQuery -Query @"
MATCH (n)
DETACH DELETE n
"@

Clear-Neo4j # Does the same, also kills indexes and constraints

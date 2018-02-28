# So!  We have data, now we can build tools
# cmdb module
# poshbot
# hook in alert routing, add context to alerts, etc.

# Don't read into this
# you can get much fancier with parameters and query building
function Get-AIDBServer {
    param ($Hostname = '.*')
    Invoke-Neo4jQuery -Query "MATCH (n:Server)
                              WHERE n.AIDBHostName =~ {Hostname}
                              RETURN n" `
                      -Parameters @{
                          Hostname = $Hostname
                      }
}

Get-AIDBServer | Select AIDB*, PDB*, AD*


function Get-AIDBService {
    param ($Name = '.*')
    Invoke-Neo4jQuery -Query "MATCH (n:Service)
                              WHERE n.name =~ {name} OR
                                    n.name_key =~ {name}
                              RETURN n" `
                      -Parameters @{
                          name = $Name
                      }
}

Get-AIDBService

function Get-AIDBDependentServices {
    param ($Name)
    Invoke-Neo4jQuery -Query "MATCH (x)-[r:DependsOn*]->(s:Service)
                              WHERE s.name = {name}
                              RETURN DISTINCT x" `
                      -Parameters @{
                          name = $Name
                      } -as Row
}

Get-AIDBDependentServices -Name 'Active Directory'
# hmm?  why is AD in there?

# etc!  You'd be surprised how handy a database of servers alone is...

# Get-AIDBServiceOutageImpact
# Get-AIDBServerOutageImpact
# Get-AIDBServiceUsers
# Get-AIDBScheduledTask
# Get-AIDBMSSQLInstance
# Get-AIDBMSSQLDatabase
# etc.
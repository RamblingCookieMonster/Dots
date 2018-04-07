# So!  We have data, now we can build tools
# cmdb module
# poshbot
# hook in alert routing, add context to alerts, etc.

# Don't read into this
# you can get much fancier with parameters and query building
function Get-DotsServer {
    param ($Hostname = '.*')
    Invoke-Neo4jQuery -Query "MATCH (n:Server)
                              WHERE n.DotsHostname =~ {Hostname}
                              RETURN n" `
                      -Parameters @{
                          Hostname = $Hostname
                      }
}

Get-DotsServer | Select Dots*, PDB*, AD*


function Get-DotsService {
    param ($Name = '.*')
    Invoke-Neo4jQuery -Query "MATCH (n:Service)
                              WHERE n.name =~ {name} OR
                                    n.name_key =~ {name}
                              RETURN n" `
                      -Parameters @{
                          name = $Name
                      }
}

Get-DotsService

function Get-DotsDependentServices {
    param ($Name)
    Invoke-Neo4jQuery -Query "MATCH (x)-[r:DependsOn*]->(s:Service)
                              WHERE s.name = {name}
                              RETURN DISTINCT x" `
                      -Parameters @{
                          name = $Name
                      } -as Row
}

Get-DotsDependentServices -Name 'Active Directory'
# hmm?  why is AD in there?

# etc!  You'd be surprised how handy a database of servers alone is...

# Get-DotsServiceOutageImpact
# Get-DotsServerOutageImpact
# Get-DotsServiceUsers
# Get-DotsScheduledTask
# Get-DotsMSSQLInstance
# Get-DotsMSSQLDatabase
# etc.
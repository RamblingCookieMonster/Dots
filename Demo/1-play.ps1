. "$PSScriptRoot\Mocks.ps1"

Get-ADComputer | New-Neo4jNode -Label Server -Passthru

# Create some services
[pscustomobject]@{
    Name = 'Active Directory'
    Description = 'Identity and related services'
},
[pscustomobject]@{
    Name = 'DNS'
    Description = 'Domain naming system'
},
[pscustomobject]@{
    Name = 'DSC'
    Description = 'Configuration management pull server'
},
[pscustomobject]@{
    Name = 'GitLab'
    Description = 'Source control and CI/CD'
},
[pscustomobject]@{
    Name = 'WebThingy'
    Description = 'Important internal web service'
} |
    New-Neo4jNode -Label Service -Passthru

# See what we have
Invoke-Neo4jQuery -Query @"
MATCH (n)
RETURN n
"@ | Format-List -Property * -Force

# Relate to AD
New-Neo4jRelationship -LeftLabel Server -LeftHash @{AIDBHostName = 'dc01'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }

New-Neo4jRelationship -LeftLabel Server -LeftHash @{AIDBHostName = 'dc02'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }

# Relate to DNS - Use cypher to do a few at once
New-Neo4jRelationship -LeftQuery "MATCH (left:Server) WHERE left.AIDBHostName =~ 'dc.*'" `
                      -RightQuery "MATCH (right:Service { Name: 'Active Directory'})" `
                      -Type 'IsPartOf' `
                      -Properties @{
                          ServiceHost = $True
                          LoadBalanced = $True
                      }

# Others
New-Neo4jRelationship -LeftLabel Server -LeftHash @{AIDBHostName = 'cfgmgmt01'} `
                      -RightLabel Service -RightHash @{Name = 'DSC'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }
New-Neo4jRelationship -LeftLabel Server -LeftHash @{AIDBHostName = 'gitlab01'} `
                      -RightLabel Service -RightHash @{Name = 'GitLab'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }
New-Neo4jRelationship -LeftLabel Server -LeftHash @{AIDBHostName = 'web01'} `
                      -RightLabel Service -RightHash @{Name = 'WebThingy'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }

#Dependencies
New-Neo4jRelationship -LeftLabel Service -LeftHash @{Name = 'Active Directory'} `
                      -RightLabel Service -RightHash @{Name = 'DSC'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'No configuration changes'
                      }
New-Neo4jRelationship -LeftLabel Service -LeftHash @{Name = 'DSC'} `
                      -RightLabel Service -RightHash @{Name = 'GitLab'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'No updates to DSC code'
                      }
New-Neo4jRelationship -LeftLabel Service -LeftHash @{Name = 'GitLab'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'Local, SSH auth only, no collaboration features (these use AD accounts)'
                      }
New-Neo4jRelationship -LeftLabel Service -LeftHash @{Name = 'WebThingy'} `
                      -RightLabel Service -RightHash @{Name = 'GitLab'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'No updates to WebThingy code'
                      }
New-Neo4jRelationship -LeftLabel Service -LeftHash @{Name = 'WebThingy'} `
                      -RightLabel Service -RightHash @{Name = 'Active Directory'} `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'Service outage'
                      }

# Everything depends on DNS...
New-Neo4jRelationship -LeftQuery "MATCH (left:Service) WHERE left.Name <> 'DNS'" `
                      -RightQuery "MATCH (right:Service { Name: 'DNS'})" `
                      -Type 'DependsOn' `
                      -Properties @{
                          OutageImpact = 'No DNS name resolution'
                      }
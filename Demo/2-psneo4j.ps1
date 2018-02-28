$DotsPath = 'E:\Dots'
Import-Module $DotsPath\.requirements\psneo4j -Force

Clear-Neo4j

ise $DotsPath\Data\Mocks.ps1
. $DotsPath\Data\Mocks.ps1
Get-ADComputer

Get-ADComputer | New-Neo4jNode -Label Server -Passthru

[pscustomobject]@{
    name = 'Active Directory'
    qualifier = 'ad.contoso.com'
    keywords = 'ldap', 'ldaps', 'kerberos', 'identity', 'authentication'
    description = 'identity, authentication, and related services'
    security_tier = 0
    outage_tier = 0
} | New-Neo4jNode -Label Service -Passthru


# Set properties on an existing node
Set-Neo4jNode -Label Server -Hash @{ Name = 'psbot01'} -InputObject @{
    CanonicalName = 'ad.contoso.com/Test/psbot01'
    ExtraData = 'why would you even add this!'
} -Verbose

# See what we have
Invoke-Neo4jQuery -Query @"
MATCH (n)
RETURN n
"@ | Format-List -Property * -Force

# Relate to AD
New-Neo4jRelationship -LeftLabel Server -LeftHash @{DNSHostname = 'dc01.ad.contoso.com'} `
                      -RightLabel Service -RightHash @{name = 'Active Directory'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      }

New-Neo4jRelationship -LeftLabel Server -LeftHash @{DNSHostname = 'dc02.ad.contoso.com'} `
                      -RightLabel Service -RightHash @{name = 'Active Directory'} `
                      -Type 'IsPartOf' `
                      -Properties @{
                          LoadBalanced = $True
                          HighlyAvailable = $True
                      } -Passthru

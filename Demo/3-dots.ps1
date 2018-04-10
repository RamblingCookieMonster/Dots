Install-Module Dots -Force
Import-Module Dots -Force

# Change default neo4j/neo4j cred, update psneo4j module configuration
$Password = ConvertTo-SecureString -String "some secure password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $Password
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://192.168.99.100:7474' # docker machine
#Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://127.0.0.1:7474' # local install

# Check dots config:
Get-DotsConfig

Get-Help Set-DotsConfig -Full
Set-DotsConfig -TestMode

# Important bits:
#   TestMode:  Use Mock functions and data from Dots/Mock
#   ScriptsPath, DataPath:  You might want this outside the module folder!
#   ScriptsToIgnore:  Lets you ignore data sources you don't have - e.g. PuppetDB

Clear-Neo4j
Connect-TheDots -WhatIf
Connect-TheDots -WhatIf -Include ADComputers
Connect-TheDots -WhatIf -DataSource DotsSources

Connect-TheDots -Confirm:$False

# Dots itself works cross platform, but external sources might not (e.g. AD...)
# We're using mock data via Set-DotsConfig -TestMode

code ./Demo/4-tools.ps1
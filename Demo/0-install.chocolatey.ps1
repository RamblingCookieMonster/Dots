# go as simple and risky as choco install from the public repo, to HA neo4j enterprise in containers

# Bootstrap chocolatey, install neo4j with defaults
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install neo4j-community -y

# Get PSNeo4j
Install-Module PSNeo4j -Force
Import-Module PSNeo4j -Force

# Set initial password and psneo4j config
$Password = ConvertTo-SecureString -String "some secure password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $Password
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://127.0.0.1:7474'

# Connecting from a remote host?
# Uncomment dbms.connectors.default_listen_address=0.0.0.0
# In "C:\tools\neo4j-community\neo4j-community-3.2.3\conf\neo4j.conf" - note version number may change

Get-Neo4jUser
Get-Neo4jActiveConfig | Format-List
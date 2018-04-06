# Not intended as a generic works-for-everyone approach
# Handy for giving quick demos or spinning up an instance for testing

# I'm using docker-machine, other envs won't need this - https://docs.docker.com/toolbox/
docker-machine create --driver virtualbox default
docker-machine env --shell=powershell default | Invoke-Expression

# Spin up a container with some published ports and mounted volumes
New-Item -ItemType Directory -Path "$ENV:HOME/neo4j" -Force
docker run --name dots `
           -p=7474:7474 `
           -p=7687:7687 `
           -p=7473:7473 `
           -v="$ENV:HOME/neo4j/dots/data:/data" `
           -v="$ENV:HOME/neo4j/dots/logs:/logs" `
           neo4j:latest

# grab the IP, can't use localhost...
docker-machine ip
# browse: http://192.168.99.100:7474/browser/

# Install psneo4j
Install-Module PSNeo4j -Force
Import-Module PSNeo4j -Force

# Set initial password and psneo4j config
$Password = ConvertTo-SecureString -String "some secure password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $Password
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://192.168.99.100:7474' # 'http://127.0.0.1:7474'

# Connecting from a remote host?
# Uncomment dbms.connectors.default_listen_address=0.0.0.0
# In "C:\tools\neo4j-community\neo4j-community-3.2.3\conf\neo4j.conf"

Get-Neo4jUser
Get-Neo4jActiveConfig | Format-List

# tear down
docker kill dots
docker rm dots
Remove-Item /Users/wframe/neo4j/dots -Recurse -Force
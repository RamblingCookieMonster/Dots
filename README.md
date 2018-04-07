# Dots

This is a janky CMDB-lite that uses PowerShell, neo4j, and a little duct-tape.

## What can Dots do?

Out of the box, we can query external sources for:

* `Servers`, via
  * Active Directory computer accounts
  * PuppetDB nodes and facts
* `Users`, via
  * Active Directory user accounts
* `Groups`, via
  * Active Directory groups
* `Group memberships`, via
  * Active Directory

We can also define data where Dots is the source of truth:

* `Services` i.e. Active Directory, not NTDS
* `Service composition` i.e. what servers or services make up a service
* `Service dependencies` i.e. what servers and services does a service depend on

## How do I get Started?

### Initial installation and configuration

* Install neo4j somewhere
  * [Chocolatey](Demo/0-install.chocolatey.ps1), [docker](0-install.docker.ps1) examples
  * Glenn's references on [chocolatey](https://glennsarti.github.io/blog/graph-all-the-powershell-things/) or [a Neo4j Enterprise cluster in docker for Windows](https://glennsarti.github.io/blog/neo4j-nano-containers/).
  * Anything else.  Neo4j and Dots don't require Windows

* Install and configure Dots

```powershell
# Install Dots and required modules - powershell-yaml and psneo4j
Install-Module Dots

# Change from the initial neo4j:neo4j creds
$Credential = Get-Credential -UserName neo4j -Message 'Password for user neo4j'
Set-Neo4jPassword -Password $Credential.Password

# Configure PSNeo4j
$BaseUri = 'http://192.168.99.100:7474' # or 'http://127.0.0.1:7474', etc.
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri $BaseUri

# Are we connected?
Get-Neo4jUser

# Get details on what we can configure
Get-DotsConfig
```

### Using Dots

```powershell
Import-Module Dots -Force
Get-Help Connect-TheDots -Full

# Check what would run by default
Connect-TheDots -Whatif

# Run it!  We prompt for each DotsSources/ExternalSources script unless you -confirm:$False
Connect-TheDots

# Browse the the $BaseUri to explore at the GUI
# User: neo4j, password: $Credential.GetNetworkCredential().Password
$BaseUri

# Explore with cypher and psneo4j

# What labels exist?  Pick one, get all nodes with that label!
Get-Neo4jLabel
Invoke-Neo4jQuery 'MATCH (n:Server) RETURN n'

# Show server-ispartof-service map
Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN s.DotsHostname AS ComputerName,
       type(r) AS Relationship,
       svc.name AS ServiceName
"@ -As ParsedColumns | Format-Table -AutoSize

# show service-uses-servers map
Invoke-Neo4jQuery -Query @"
MATCH (s:Server)-[r:IsPartOf]->(svc:Service)
RETURN {
    ServiceName: svc.name,
    Servers: collect(s.DotsHostname)
}
"@ -as Row

# Delete all data, indices, and constraints
Clear-Neo4j
```

## What do I need to configure?

* `Dots\dots.conf` points to three paths.        See the file for in depth explanations
  * `ScriptsPath`  default: `Dots\Scripts`       The scripts that query ExternalSources and DotsSources live here
  * `DataPath`     default: `Dots\Data`          DotsSources yaml data lives here (e.g. service definitions)
* `Set-DotsConfig` default: See `Get-DotsConfig` Various Dots configurations

## Does this support <insert technology>?

This is up to you!  Ultimately, `Connect-TheDots` will run whatever you put in the `ScriptsPath`s.

You might consider:

* Submitting an issue with the idea, including
  * What it should create (nodes, relationships, both)
  * What it creates:
    * Node label, and if label exists, consider a common prefix
    * Relationship type, and ways to identify start and end nodes
  * Whether the data source should be Dots (`DotsSources`) or external (`ExternalSources`)
* Borrowing existing code in `ExternalSources` or `DotsSources`, adjusting to meet your needs.  Or just write it from scratch, my examples are a bit ugly!
* Submitting a pull request!

I'll generally be happy to accept extensions directly to this project, with the caveat that:

* I might be somewhat picky about property names and prefixes, if you're adding to an existing node label
* I might not include your script in the default whitelist of scripts to run
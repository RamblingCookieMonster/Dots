# Dots

This is a janky, POC CMDB-lite that uses PowerShell, neo4j, and a little duct-tape

_WARNING_: This is at the _maybe sufficient for demo purposes_ stage.  No tests.  Many assumptions.  Use at your own risk : )

## What can Dots do?

Out of the box, we can query external sources for:

* `Servers`, via
  * Active Directory computer accounts
  * PuppetDB nodes and facts (soon)
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

We take all this information, and connect the dots with Neo4j and some sloppy code

## How do I get Started?

### Initial installation and configuration

* Install neo4j somewhere
  * [Chocolatey](Demo/0-install.chocolatey.ps1), [docker](0-install.docker.ps1) examples
  * Glenn's references on [chocolatey](https://glennsarti.github.io/blog/graph-all-the-powershell-things/) or [a Neo4j Enterprise cluster in docker for Windows](https://glennsarti.github.io/blog/neo4j-nano-containers/).
  * Neo4j doesn't require Windows!

* Install and configure Dots

```powershell
# Install Dots and required modules - powershell-yaml and psneo4j
Install-Module Dots

# Configure PSNeo4j URI
Set-PSNeo4jConfiguration -BaseUri 'http://127.0.0.1:7474' # likely 'http://192.168.99.100:7474' for docker machine, etc.

# Change from the initial neo4j:neo4j creds, save config
$Credential = Get-Credential -UserName neo4j -Message 'Password for user neo4j'
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential

# Are we connected?
Get-Neo4jUser

# Get details on what we can configure
Get-DotsConfig
```

### Using Dots

```powershell
# Assumption: You've already Set-PSNeo4jConfiguration to the right BaseUri/credential

Import-Module Dots -Force

# Check the default configs
Get-DotsConfig

# Check Set-DotsConfig, set things as desired.  We'll use mock data via 'TestMode'
Get-Help Set-DotsConfig -Full
Set-DotsConfig -TestMode

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

Most configuration involves `Get-DotsConfig` and `Set-DotsConfig`

Some things to consider:

* `ScriptsPath` and `DataPath` live under the module by default.  Move these elsewhere to avoid losing them if you remove or update the module
* You might not have all of the data sources we support by default.  Use `ScriptsToIgnore` to exclude these
* This DotsConfig data is serialized in a file identified via `Get-DotsConfigPath`
* We heavily use [PSNeo4j](https://github.com/RamblingCookieMonster/PSNeo4j).  You can use `Set-PSNeo4jConfiguration` and `Get-PSNeo4jConfiguration` to configure this.  At a minimum, you'll need to specify the `BaseUri` and `Credential`

## Does this support \<insert technology>?

This is up to you!  Ultimately, `Connect-TheDots` will run whatever you put in the `ScriptsPath`s (Danger!)

You might consider:

* Submitting an issue with your idea, including
  * What it should create (nodes, relationships, both)
  * What it creates:
    * Node label, and if label exists, consider a common prefix
    * Relationship type, and ways to identify start and end nodes
  * Whether the data source should be Dots (`DotsSources`) or external (`ExternalSources`)
* Borrowing existing code in `ExternalSources` or `DotsSources`, adjusting to meet your needs.  Or just write it from scratch, my examples are a bit ugly!
* Submitting a pull request!

I'll generally be happy to accept extensions directly to this project, with the caveat that:

* I might be somewhat picky about property names and prefixes, if you're adding to an existing node label
* I might add your script in the default ScriptsToIgnore list if it's a niche data source
# This is in the 'get it working' stage - will change significantly...
$DotsPath = '~/sc/Dots/Dots'

Invoke-PSDepend -Path $DotsPath/.requirements.psd1 -Install -Import -Force
Import-Module "/Users/wframe/sc/Dots/Dots" -Force

# Install Dots
# Check configurations:
  # ModulePath\Dots\dots.conf  : Tells dots where scripts, data, and conf files are

  # ScriptsPath (in dots.conf) : Tells dots where to find scripts (manual or auto)
  # ConfPath (in dots.conf)    : Stores 'config' scripts (~params for ScriptPath scripts, with logic.  ugly af but works for me, sorry)
  # DataPath (in dots.conf)    : Tells dots where to find yaml data for manual scripts

  #TODO: Delivery mechanism for scripts (repo + psdepend? keep in here?)

# Change default neo4j/neo4j cred, update psneo4j module configuration
$Password = ConvertTo-SecureString -String "some secure password" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList neo4j, $Password
Set-Neo4jPassword -Password $Credential.Password
Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://192.168.99.100:7474' # docker machine
#Set-PSNeo4jConfiguration -Credential $Credential -BaseUri 'http://127.0.0.1:7474' # local install

Clear-Neo4j

Connect-TheDots -WhatIf
Connect-TheDots -WhatIf -Include ADComputers
Connect-TheDots -WhatIf -Scope Manual


Connect-TheDots -Confirm:$False -Verbose


Clear-Neo4j
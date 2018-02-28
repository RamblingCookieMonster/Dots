# This is in the 'get it working' stage - will change significantly...

$DotsPath = 'E:\Dots'
Invoke-PSDepend -Path $DotsPath\.requirements.psd1 -Install -Import -Force
Import-Module E:\Dots -Force

Clear-Neo4j


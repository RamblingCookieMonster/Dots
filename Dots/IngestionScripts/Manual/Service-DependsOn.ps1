#service-dependson-server
Invoke-Neo4jQuery "MATCH (:Service)-[r:DependsOn]->() DELETE r"
Invoke-Neo4jQuery -Query "MATCH ()-[r:IsPartOf]->(:Service) DELETE r"

"`n###############"
"Running $($MyInvocation.MyCommand.Name )"
"###############"
$files = Get-ChildItem $DataPath\Service-DependsOn\*.yml -File | Where-Object {$_.BaseName -notmatch '^[0-9].*Template$'}
foreach($file in $files) {
    "### PARSING ### $($file.fullname)"
    $yaml = Get-Content $file.fullname -Raw
    $data = ConvertFrom-Yaml -Yaml $yaml
    foreach($DependencyKey in $data.keys) {
        $Params = @{
            Passthru = $True
        }
        $Dependency = $data[$DependencyKey]
        if($Dependency.name) {
            $DependencyName = $Dependency.Name
        }
        else {
            $DependencyName = $file.BaseName
        }
        if($Dependency.ContainsKey('properties') -and $Dependency.properties.keys.count -gt 0) {
            $Params.add('Properties', $Dependency.properties)
        }
        $PartOfService = $false
        if($Dependency.ContainsKey('part_of_service') -and $Dependency['part_of_service']) {
            $PartOfService = $True
        }

        if($Dependency.ContainsKey('servers') -and $Dependency.servers.count -gt 0) {
            $Left = "MATCH (left:Service) WHERE left.name_key = {name} OR left.name = {name}"
            $Right = "MATCH (right:Server) WHERE right.${CMDBPrefix}HostName IN {servers}"
            $Output = New-Neo4jRelationship @Params -LeftQuery $Left `
                                                    -RightQuery $Right `
                                                    -Type DependsOn `
                                                    -Parameters @{
                                                        name = $DependencyName
                                                        servers = $Dependency.servers
                                                    }
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($Data[$DependencyKey] | Out-String) `
                           -DataKey $DependencyKey `
                           -Specific "service [$DependencyName], DependsOn servers [$($Dependency.servers)]" `
                           -Output $Output

            if($PartOfService) {
                $Left = "MATCH (left:Server) WHERE left.${CMDBPrefix}HostName IN {servers}"
                $Right = "MATCH (right:Service) WHERE right.name_key = {name} OR right.name = {name}"
                $Output = New-Neo4jRelationship @Params -LeftQuery $Left `
                                                        -RightQuery $Right `
                                                        -Type IsPartOf `
                                                        -Parameters @{
                                                            name = $DependencyName
                                                            servers = $Dependency.servers
                                                        }
                Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                               -YamFile $File `
                               -DataHash $($Data[$DependencyKey] | Out-String) `
                               -DataKey $DependencyKey `
                               -Specific "service [$DependencyName], IsComposedOf servers [$($Dependency.servers)]" `
                               -Output $Output
            }
        }
        if($Dependency.ContainsKey('services') -and $Dependency.services.count -gt 0) {
            $Left = "MATCH (left:Service) WHERE left.name_key = {name} OR left.name = {name}"
            $Right = "MATCH (right:Service) WHERE right.name IN {services} OR right.name_key IN {services}"
            $Output = New-Neo4jRelationship @Params -LeftQuery $Left `
                                                    -RightQuery $Right `
                                                    -Type DependsOn `
                                                    -Parameters @{
                                                        name = $DependencyName
                                                        services = $Dependency.services
                                                    }
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($Data[$DependencyKey] | Out-String) `
                           -DataKey $DependencyKey `
                           -Specific "service [$DependencyName], services [$($Dependency.services)]" `
                           -Output $Output
            if($PartOfService) {
                $Left = "MATCH (left:Service) WHERE left.name_key = {name} OR left.name = {name}"
                $Right = "MATCH (right:Service) WHERE right.name IN {services} OR right.name_key IN {services}"
                $Output = New-Neo4jRelationship @Params -LeftQuery $Left `
                                                        -RightQuery $Right `
                                                        -Type IsPartOf `
                                                        -Parameters @{
                                                            name = $DependencyName
                                                            services = $Dependency.services
                                                        }
                Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                               -YamFile $File `
                               -DataHash $($Data[$DependencyKey] | Out-String) `
                               -DataKey $DependencyKey `
                               -Specific "service [$DependencyName], services [$($Dependency.services)]" `
                               -Output $Output            }
        }
    }
}

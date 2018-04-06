[cmdletbinding()]
param(
    $RelationshipTypes = @('Uses', 'Admins', 'Owns', 'Owns_Data')
)

<#
    Build up services and principal relationships
    Delete all existing data beforehand
#>
foreach($RelationshipType in $RelationshipTypes) {
    Invoke-Neo4jQuery -Query "MATCH ()-[r:$RelationshipType]->() DELETE r"
}
Invoke-Neo4jQuery -Query "MATCH (s:Service) DETACH DELETE s"

$ScriptName = $MyInvocation.MyCommand.Name -replace '.ps1$'
"`n###############"
"Running $ScriptName"
"###############"
$files = Get-ChildItem $DataPath\$ScriptName\*.yml -File | Where-Object {$_.BaseName -notmatch '^[0-9].*Template.*'}

foreach($file in $files) {
    "### PARSING ### $($file.fullname)"
    $yaml = Get-Content $file.fullname -Raw
    $data = ConvertFrom-Yaml -Yaml $yaml
    $namekey = $file.basename
    # Extract reserved keys that aren't a part of the service
    $Sleep = $null
    $PrincipalData = @{}
    foreach($RelationshipType in $RelationshipTypes){
        if($data.ContainsKey($RelationshipType)){
            $PrincipalData.add($RelationshipType, $data[$RelationshipType])
            [void]$data.remove($RelationshipType)
            $Sleep = $True
        }
    }

    # Create the service
    $Output = Set-Neo4jNode -Label Service -Hash @{name_key = $namekey} -InputObject $data -Passthru
    Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                   -YamFile $File `
                   -DataHash $($Data | Out-String) `
                   -DataKey $namekey `
                   -Specific "service $namekey" `
                   -Output $Output

    foreach($RelationshipType in $RelationshipTypes){
        if(-not $PrincipalData.ContainsKey($RelationshipType)) {
            continue
        }

        $Params = @{
            RightLabel = 'Service'
            RightHash = @{name_key = $namekey}
            Type = $RelationshipType
        }
        $Principals = $PrincipalData[$RelationshipType]
        foreach($Principal in $Principals.Keys) {
            $LeftParams = @{
                LeftLabel = Get-PrincipalLabel -Name $Principal
                LeftHash = @{ADSamAccountName = $Principal}
                Properties = $Principals[$Principal]
            }
            $Output = New-Neo4jRelationship @LeftParams @Params -Passthru -verbose
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($PrincipalData | Out-String) `
                           -DataKey $namekey `
                           -Specific "principal $Principal [:$RelationshipType] service $namekey" `
                           -Output $Output
        }
    }
}

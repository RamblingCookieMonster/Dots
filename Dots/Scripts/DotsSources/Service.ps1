    <#
    .SYNOPSIS
        Read Service definitions, add to Neo4j

    .DESCRIPTION
        Read Service definitions, add to Neo4j

        This is invoked by Connect-TheDots

    .PARAMETER RelationshipTypes
        Whitelist of user/group relationship types to this service.
        Defaults to Uses, Admins, Owns, Owns_Data

    .PARAMETER Path
        Path to yaml files
        Defaults to DataPath\Service\*.yml

        If TestMode is set, we override this to Dots/Mock/Data/*.yml
    .FUNCTIONALITY
        Dots
    #>
[cmdletbinding()]
param(
    $RelationshipTypes = @('Uses', 'Admins', 'Owns', 'Owns_Data'),
    $Path
)
$ScriptName = $MyInvocation.MyCommand.Name -replace '.ps1$'
if($Script:TestMode){
    $Path = "$ModuleRoot/Mock/Data/$ScriptName/*.yml"
}
elseif(-not $PSBoundParameters.ContainsKey('Path')){
    $Path = "$script:DataPath/$ScriptName/*.yml"
}
Write-Verbose "Parsing $ScriptName files from $Path"
# Build up services and principal relationships
# Delete all existing data beforehand
foreach($RelationshipType in $RelationshipTypes) {
    Invoke-Neo4jQuery -Query "MATCH ()-[r:$RelationshipType]->(:Service) DELETE r"
}
Invoke-Neo4jQuery -Query "MATCH (s:Service) DETACH DELETE s"

"`n###############"
"Running $ScriptName"
"###############"
$files = Get-ChildItem $Path -File | Where-Object {$_.BaseName -notmatch '^[0-9].*Template.*'}
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
            $Output = New-Neo4jRelationship @LeftParams @Params -Passthru
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($PrincipalData | Out-String) `
                           -DataKey $namekey `
                           -Specific "principal $Principal [:$RelationshipType] service $namekey" `
                           -Output $Output
        }
    }
}

 <#
.SYNOPSIS
     Read Account-Approves-Group definitions, add to Neo4j

.DESCRIPTION
    Read Account-Approves-Group definitions, add to Neo4j

    This clears out existing ApprovesMembership relationships before populating neo4j

    See Dots/Data/Account-Approves-Group/0.template.yml for schema and an example

    This is invoked by Connect-TheDots

.PARAMETER Path
    Path to yaml files
    Defaults to DataPath\Account-Approves-Group\*.yml
    We append Account-Approves-Group/*.yml to this path

    If TestMode is set, we override this to Dots/Mock/Data/*.yml
.FUNCTIONALITY
    Dots
#>
[cmdletbinding()]
param(
    [string[]]$Path
)

$ScriptName = $MyInvocation.MyCommand.Name -replace '.ps1$'

Invoke-Neo4jQuery "MATCH ()-[r:ApprovesMembership]->(:Group) DELETE r"

if($Script:TestMode){
    $Path = "$ModuleRoot/Mock/Data/$ScriptName/*.yml"
}
elseif(-not $PSBoundParameters.ContainsKey('Path')){
    $Path = $script:DataPath
}
Write-Verbose "Parsing $ScriptName files from [$Path]"
"`n###############"
"Running $ScriptName "
"###############"

foreach($PathItem in $Path) {
    $PathItem = Join-Path $PathItem "/$ScriptName/*.yml"
    $files = Get-ChildItem $PathItem -File | Where-Object {$_.BaseName -notmatch '^[0-9].*Template$'}

    foreach($file in $files) {
        "### PARSING ### $($file.fullname)"
        $yaml = Get-Content $file.fullname -Raw
        $data = ConvertFrom-Yaml -Yaml $yaml

        foreach($Group in $data.keys) {
            foreach($Approver in $Data[$Group].approvers) {
                $Label = $null
                $Label = Get-PrincipalLabel -Name $Approver
                if(-not $Label) {continue}
                $Params = @{
                    Type = 'ApprovesMembership'
                    LeftLabel = $Label
                    LeftHash = @{ADSamAccountName = $Approver}
                    RightLabel = 'Group'
                    Passthru = $True
                }
                if($Data[$Group].ContainsKey('Properties') -and $Data[$Group].Properties -is [hashtable])
                {
                    $Params.add('Properties', $Data[$Group].Properties)
                }
                if($Data[$Group].parameters.regex) {
                    $Groups = Invoke-Neo4jQuery -Query "MATCH (n:Group) WHERE n.ADSamAccountName =~ `$Group RETURN n.ADSamAccountName" -Parameters @{Group = "$Group"} | foreach-object {$_.Neo4jData}
                }
                else {
                    $Groups = @($Group)
                }
                foreach($TargetGroup in $Groups) {
                    $Output = @( New-Neo4jRelationship @Params -RightHash @{ADSamAccountName = $TargetGroup})
                    Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                                -YamFile $File `
                                -DataHash $($Data[$Group] | Out-String) `
                                -DataKey $Group `
                                -Specific "Approver $Approver" `
                                -Output $Output
                }
            }
        }
    }
}
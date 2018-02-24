<#
    Build up services and principal-owns-service relationships
    Delete all existing data beforehand
#>
Invoke-Neo4jQuery -Query "MATCH (s:Service) DETACH DELETE s"
Invoke-Neo4jQuery -Query "MATCH ()-[r:Owns]->() DELETE r"

"Running $($MyInvocation.MyCommand.Name )"
"####################"
$files = Get-ChildItem $ENV:BHProjectPath\Data\Service\*.yml -File | Where-Object {$_.BaseName -notmatch '^[0-9].*Template.*'}

function Get-AccountLabel {
    [cmdletbinding()]
    param($Name)
    $Account = $null
    $Account = Get-ADSIObject $Name -Property samaccountname, objectclass
    if($Account.objectclass -like 'user'){'Account'}
    elseif($Account.objectclass -like 'group'){'Group'}
    else {
        write-warning "Could not find owner [$($OwnerHash.owner)] in AD"
    }
}

foreach($file in $files) {
    "### PARSING ### $($file.fullname)"
    $yaml = Get-Content $file.fullname -Raw
    $data = ConvertFrom-Yaml -Yaml $yaml
    $namekey = $file.basename
    # Extract reserved keys that aren't a part of the service
    $Sleep = $null
    [string[]]$Owner = if($data.ContainsKey('owner')) {
        $data['owner']
        [void]$data.remove('owner')
        $Sleep = $True
    } else {$null}

    # Create the service
    $Output = Set-Neo4jNode -Label Service -Hash @{name_key = $namekey} -InputObject $data -Passthru
    Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                   -YamFile $File `
                   -DataHash $($Data | Out-String) `
                   -DataKey $namekey`
                   -Specific "service $namekey" `
                   -Output $Output

    # Create relationships
    if($Sleep) {Start-Sleep -Milliseconds 300}
    if($Owner) {
        foreach($Account in $Owner) {
            $Label = Get-AccountLabel -Name $Account
            $LeftQuery = "MATCH (left:$Label {ADSamAccountName: {ADSamAccountName}})"
            $SQLParams = @{}
            $SQLParams.Add('ADSamAccountName', $Account)
            $Params = @{
                Type = 'Owns'
                LeftQuery = $LeftQuery
                Passthru = $True
            }
            $Right = "MATCH (right:Service {name_key: {name_key}})"
            $SQLParams.add('name_key', $namekey)
            $Output = New-Neo4jRelationship @Params -RightQuery $Right -Parameters $SQLParams
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($Data | Out-String) `
                           -DataKey $namekey`
                           -Specific "Owner $Account, service $namekey" `
                           -Output $Output
        }
    }
    if($Access) {
        foreach($Account in $Access) {
            $Label = Get-AccountLabel -Name $Account
            $LeftQuery = "MATCH (left:$Label {ADSamAccountName: {ADSamAccountName}})"
            $SQLParams = @{}
            $SQLParams.Add('ADSamAccountName', $Account)
            $Params = @{
                Type = 'Uses'
                LeftQuery = $LeftQuery
                Passthru = $true
            }
            $Right = "MATCH (right:Service {name_key: {name_key}})"
            $SQLParams.add('name_key', $namekey)

            $Params.Type = 'Uses'
            $Output = New-Neo4jRelationship @Params -RightQuery $Right -Parameters $SQLParams
            Test-BadOutput -Ingestor $MyInvocation.MyCommand.Name `
                           -YamFile $File `
                           -DataHash $($Data | Out-String) `
                           -DataKey $namekey`
                           -Specific "Uses system $Account, service $namekey" `
                           -Output $Output
        }
    }
}

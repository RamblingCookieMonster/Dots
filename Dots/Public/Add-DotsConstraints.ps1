function Add-DotsConstraints {
[cmdletbinding()]
param(
    [string]$AccountLabel = 'User',
    [string]$AccountUnique = 'ADSID',
    [string]$AccountIndexes = @(),

    [string]$GroupLabel = 'Group',
    [string]$GroupUnique = 'ADSID',

    [string]$ServerLabel = 'Server',
    [string]$ServerUnique = $Script:ServerUnique, #defined in Conf/Dots.Config.ps1
    [string[]]$ServerIndexes = @('ADNameLower', 'PDBenvironment')
)
if($ServerUnique -and $ServerLabel) {
    $Existing = $null
    $Existing = Get-Neo4jConstraint |
        Where-Object {$_.Neo4jData -like "CONSTRAINT ON ( *:$ServerLabel ) ASSERT *.$ServerUnique IS UNIQUE"}
    if(-not $Existing) {
        New-Neo4jConstraint -Label $ServerLabel -Property $ServerUnique -Unique
    }
}

if($GroupUnique -and $GroupLabel) {
    $Existing = $null
    $Existing = Get-Neo4jConstraint |
        Where-Object {$_.d -like "CONSTRAINT ON ( *:$GroupLabel ) ASSERT *.$GroupUnique IS UNIQUE"}
    if(-not $Existing) {
        New-Neo4jConstraint -Label $GroupLabel -Property $GroupUnique -Unique
    }
}

if($AccountUnique -and $AccountLabel) {
    $Existing = $null
    $Existing = Get-Neo4jConstraint |
        Where-Object {$_.d -like "CONSTRAINT ON ( *:$AccountLabel ) ASSERT *.$AccountUnique IS UNIQUE"}
    if(-not $Existing) {
        New-Neo4jConstraint -Label $AccountLabel -Property $AccountUnique -Unique
    }
}

foreach($Index in $ServerIndexes) {
    New-Neo4jIndex -Label $ServerLabel -Property $Index
}

foreach($Index in $AccountIndexes) {
    New-Neo4jIndex -Label $AccountLabel -Property $Index
}

}
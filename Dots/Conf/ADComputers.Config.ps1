[string[]]$Excludes = 'CanonicalName'
$Transforms = '*',
    @{
        label = 'ParentCanonicalName'
        expression = {$_.CanonicalName -replace "/$($_.Name)$"}
    },
    @{
        label = "NameLower"
        expression = {$_.Name.tolower()}
    }

$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date
$CruftDate = $Date.AddYears(-1)
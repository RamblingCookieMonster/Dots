$Transforms = '*',
    @{
        label = 'ParentCanonicalName'
        expression = {$_.CanonicalName -replace "/$($_.CN)$"}
    }

$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date
$CruftDate = $Date.AddYears(-1)
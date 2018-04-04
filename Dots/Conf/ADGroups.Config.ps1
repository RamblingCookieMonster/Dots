$Transforms = '*',
    @{
        label = 'ParentCanonicalName'
        expression = {$_.CanonicalName -replace "/$($_.CN)$"}
    },
    @{
        label = "Managed_By"
        expression = {
            try {
                if($_.ManagedBy) {
                    $a = $null
                    $a = $_
                    (ActiveDirectory\Get-ADObject $_.ManagedBy -Properties SamAccountName -ErrorAction Stop).SamAccountName
                }
            }
            catch {Write-Warning "$($a.Name) managed by doesn't exist:$($a.ManagedBy)"}}
    }

$Unique = "${Prefix}${MergeProperty}"
$Date = Get-Date

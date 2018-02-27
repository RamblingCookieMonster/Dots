# Credit to Dirk Bremen - https://powershellone.wordpress.com/2015/07/30/sort-data-using-a-custom-list-in-powershell/
function Sort-CustomList {
    # Example:
    # 'ab', '1', 'cba' | Sort-CustomList -List 1, cba, ab -Verbose
    # Sort incoming objects according to order in -List
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]$InputObject,
        [object[]]$List,
        [string]$SortOnProperty,
        [object[]]$Property
    )
    begin {
        $In = New-Object System.Collections.ArrayList
    }
    process {
        [void]$In.add($InputObject)
    }
    end {
        $properties = ,{
            if($SortOnProperty) {$SortOn = $_."$SortOnProperty"}
            else {$SortOn = $_}
            $rank = $List.IndexOf($SortOn)
            if($rank -ne -1){$rank}
            else{[System.Double]::PositiveInfinity}
        }
        if ($Property){
            $properties += $Property
        }
        $In | Sort-Object $properties
    }
}
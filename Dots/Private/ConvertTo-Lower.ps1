function ConvertTo-Lower {
    param(
        [object[]]$InputObject,
        [string[]]$Exclude
    )
    foreach($Object in $InputObject){
        # Get all props that are strings, convert those to lower
        $h = @{}
        $Object.psobject.Properties.ForEach({$h.add($_.name, $_.TypeNameOfValue)})
        $h.keys.where({$h[$_] -eq 'System.String'}).foreach({
            if($Exclude -notcontains $_) {
                $Object.$_ = $Object.$_.ToLower()
            }
        })
    }
}
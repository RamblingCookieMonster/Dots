[string[]]$Excludes = 'puppet_classes'
$Transforms = '*',
    @{
        label = "UpdateDate"
        expression = {$Date}
    },
    @{
        label='NameLower'
        expression={$Node.name.ToLower()}
    },
    @{
        label='Classes'
        expression={
            $Classes = $null
            if($_.puppet_classes -match "^\[.*\]$") {
                $Classes = $_.puppet_classes.trimstart('[').trimend(']') -split "," | where {$_}
                $Classes = @(
                    foreach($Class in $Classes) {
                        $Class.trim(' ').trim('"')
                    }
                )
            }
            $Classes | Sort -Unique
        }
    }
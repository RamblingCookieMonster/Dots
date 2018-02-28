[string[]]$Excludes = @('Path')
[object[]]$Transforms = '*',
    @{
        label = 'TaskPath'
        expression = {
            $_.Path -replace "^/"
        }
    },
    @{
        label = 'HostName'
        expression = {
            $_.ComputerName.ToLower()
        }
    }

$Date = Get-Date
$CruftDate = $Date.AddYears(-1)
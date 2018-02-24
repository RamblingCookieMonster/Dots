function Add-PropertyPrefix {
    param($Prefix, $Object)
    $Props = Get-PropertyOrder $Object
    $PropMap = foreach($Prop in $Props) {
        @{
            Name="$Prefix$Prop"
            Expression=[scriptblock]::create("`$_.'$Prop'")
        }
    }
    Select-Object -InputObject $Object -Property $PropMap
}
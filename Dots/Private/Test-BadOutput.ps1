function Test-BadOutput {
    param(
        $Output,
        $Ingestor,
        $YamlFile,
        $DataHash,
        $DataKey,
        $Specific
    )
    if( $Output.count -eq 0 -or (
           $Output.count -eq 1 -and
           $Output[0].psobject.properties.name.count -eq 2 -and
           $Output[0].Neo4jData -like $null
        )
    ) {
        $o = [pscustomobject]@{
            Ingestor = $Ingestor
            YamlFile = $File
            DataHash = $DataHash
            DataKey  = $DataKey
            Specific = $Specific
        }
        $Status = 'ERROR !!!!!!!'
        [void]$Followup.add($o)
    }
    else {
        $Status = '   SUCCESS   '
    }
    "$Status`: file [$File], key [$DataKey], specific [$Specific]"
}
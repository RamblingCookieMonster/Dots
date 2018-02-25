@{    # Some defaults for all dependencies
    PSDependOptions = @{
        Target = '$DependencyFolder\.requirements'
        AddToPath = $True
        Parameters = @{
            Force = $True
        }
    }

    'PSGalleryNuget::powershell-yaml' = '0.3.1'
    'PSGalleryNuget::psneo4j' = 'latest'
    'PSGalleryNuget::BuildHelpers' = 'latest'
}
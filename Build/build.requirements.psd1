@{
    # Some defaults for all dependencies
    PSDependOptions = @{
        Target = '$ENV:USERPROFILE\Documents\WindowsPowerShell\Modules'
        AddToPath = $True
    }

    'psake' = @{
        DependencyType = 'PSGalleryNuget'
        Version = '4.7.0'
    }
    'PSDeploy' = @{
        DependencyType = 'PSGalleryNuget'
        Version = '0.2.5'
    }
    'BuildHelpers' = @{
        DependencyType = 'PSGalleryNuget'
        Version = '1.1.4'
    }
    'Pester' = @{
        DependencyType = 'PSGalleryNuget'
        Version = '4.3.1'
    }
}
function Get-ADComputer {
    [pscustomobject]@{
        DotsHostname = 'dc01.ad.contoso.com'
        DNSHostname = 'dc01.ad.contoso.com'
        Name = 'dc01'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc01'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        DotsHostname = 'dc02.ad.contoso.com'
        DNSHostname = 'dc02.ad.contoso.com'
        Name = 'dc02'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc02'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        DotsHostname = 'cfgmgmt01.ad.contoso.com'
        DNSHostname = 'cfgmgmt01.ad.contoso.com'
        Name = 'cfgmgmt01'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/cfgmgmt01'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        DotsHostname = 'psbot01.ad.contoso.com'
        DNSHostname = 'psbot01.ad.contoso.com'
        Name = 'psbot01'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 1/computers/psbot01'
        lastlogondate = [datetime]::Now
    }
}

function Get-PDBNode {
    [pscustomobject]@{
        certname = 'dc01.ad.contoso.com'
        'facts-timestamp' = '2018-02-22T17:00:51.287Z'
    },
    [pscustomobject]@{
        certname = 'dc02.ad.contoso.com'
        'facts-timestamp' = '2018-02-22T17:00:51.287Z'
    },
    [pscustomobject]@{
        certname = 'cfgmgmt01.ad.contoso.com'
        'facts-timestamp' = '2018-02-22T17:00:51.287Z'
    },
    [pscustomobject]@{
        certname = 'gitlab01.ad.contoso.com'
        'facts-timestamp' = '2018-02-22T17:00:51.287Z'
    },
    [pscustomobject]@{
        certname = 'psbot01.ad.contoso.com'
        'facts-timestamp' = '2018-02-22T17:00:51.287Z'
    }
}

function Get-PDBNodeFact {
    param($Certname)
    switch($Certname) {
        'dc01.ad.contoso.com' {
            [pscustomobject]@{
                DotsHostname = 'dc01.ad.contoso.com'
                certname = 'dc01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog", "roles::service::msadds"]'
            }
        }
        'dc02.ad.contoso.com' {
            [pscustomobject]@{
                DotsHostname = 'dc02.ad.contoso.com'
                certname = 'dc02.ad.contoso.com'
                environment = 'wframe/winlogbeat'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::winlogbeat", "roles::service::msadds"]'
            }
        }
        'cfgmgmt01.ad.contoso.com' {
            [pscustomobject]@{
                DotsHostname = 'cfgmgmt01.ad.contoso.com'
                certname = 'cfgmgmt01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog"]'
            }
        }
        'gitlab01.ad.contoso.com' {
            [pscustomobject]@{
                DotsHostname = 'gitlab01.ad.contoso.com'
                certname = 'gitlab01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "roles::service::gitlab"]'
            }
        }
        'psbot01.ad.contoso.com' {
            [pscustomobject]@{
                DotsHostname = 'psbot01.ad.contoso.com'
                certname = 'psbot01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog", "roles::psbot"]'
            }
        }
    }
}

function Get-ADUser {
    [pscustomobject]@{
        SamAccountName = 'aboss'
        userprincipalname = 'aboss@ad.contoso.com'
        title = 'boss'
        mail = 'aboss@contoso.com'
        sid = @{value = 'S-1-5-21-1004336348-1177238915-682003330-00000'}
        distinguishedname = 'CN=aboss,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=psbot-users,OU=Domain Groups,DC=ad,DC=contoso,DC=com', 'CN=psbot-admins,OU=groups,OU=tier 1,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now
    }
    [pscustomobject]@{
        SamAccountName = 'wframe'
        userprincipalname = 'wframe@ad.contoso.com'
        title = 'sysadmin'
        mail = 'wframe@contoso.com'
        sid = @{value = 'S-1-5-21-1004336348-1177238915-682003330-11111'}
        distinguishedname = 'CN=wframe,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=psbot-users,OU=Domain Groups,DC=ad,DC=contoso,DC=com', 'CN=psbot-admins,OU=groups,OU=tier 1,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        SamAccountName = 'wframet0'
        userprincipalname = 'wframet0@ad.contoso.com'
        title = 'sysadmin'
        mail = ''
        sid = @{value='S-1-5-21-1004336348-1177238915-682003330-22222'}
        distinguishedname = 'CN=wframet0,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=Domain Admins,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now
    }
}

function Get-ADGroup {
    [pscustomobject]@{
        SamAccountName = 'Domain Admins'
        name = 'Domain Admins'
        distinguishedname = 'CN=Domain Admins,CN=Users,DC=ad,DC=contoso,DC=com'
        SID = @{value='S-1-5-21-1004336348-1177238915-682003330-512'}
    },
    [pscustomobject]@{
        SamAccountName = 'Domain Users'
        name = 'Domain Users'
        distinguishedname = 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com'
        SID = @{value='S-1-5-21-1004336348-1177238915-682003330-513'}
    },
    [pscustomobject]@{
        SamAccountName = 'psbot-users'
        name = 'psbot-users'
        distinguishedname = 'CN=psbot-users,OU=Domain Groups,DC=ad,DC=contoso,DC=com'
        managedby = 'CN=wframe,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        SID = @{value='S-1-5-21-1004336348-1177238915-682003330-222222'}
    },
    [pscustomobject]@{
        SamAccountName = 'psbot-admins'
        name = 'psbot-admins'
        distinguishedname = 'CN=psbot-admins,OU=groups,OU=tier 1,DC=ad,DC=contoso,DC=com'
        managedby = 'CN=wframe,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        SID = @{value='S-1-5-21-1004336348-1177238915-682003330-333333'}
    }
}

function ActiveDirectory\Get-ADObject {
    param($Identity, $Properties)
    if($Identity -eq 'CN=wframe,OU=Domain Users,DC=ad,DC=contoso,DC=com') {
        [pscustomobject]@{
            SamAccountName = 'wframe'
        }
    }
}

function Get-ScheduledTasks {
    [pscustomobject]@{
        ComputerName = 'psbot01'
        Name = 'Watch-PSBot'
        Path = '\Watch-PSBot'
        Enabled = $True
        Action = 'C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe'
        Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "C:\tasks\Watch-PSBot.ps1"'
        UserId = 'NT AUTHORITY\System'
        LastRunTime = Get-Date "2/26/2018 9:03:27 PM"
        NextRunTime = Get-Date "2/26/2018 9:13:28 PM"
        Status = 'Ready'
        Author = 'contoso\wframe'
        RunLevel = 'HighestAvailable'
        Description = 'Watch for PSBot presence -ne active'
    }
}

function Get-SqlInstance {
    # Simple:
        # https://gallery.technet.microsoft.com/scriptcenter/Get-SQLInstance-9a3245a0
        # Borrowed from Boe's example data
    # More complex:
        # Various dbatools for querying instance info, including https://dbatools.io/functions/get-dbasqlinstanceproperty/
    [pscustomobject]@{
        ComputerName = 'mssql01'
        FullName = 'SQLCLU\MSSQLSERVER'
        Instance = 'MSSQLSERVER'
        SqlServer = 'SQLCLU'
        Version = '10.53.6000.34'
        Splevel = 3
        Clustered = $False
        Installpath = 'C:\Program Files\Microsoft SQL Server\MSSQL10_50.MSSQLSERVER\MSSQL'
        Datapath = 'D:\MSSQL10_50.MSSQLSERVER\MSSQL'
        Caption = 'SQL Server 2008 R2'
        BackupDirectory = 'F:\MSSQL10_50.MSSQLSERVER\MSSQL\Backup'
    }
}

function Get-Disk {
    [pscustomobject]@{
        DeviceID = ''
        ComputerName = ''
        Path = ''
        VolumeName = ''
        SCSITarget = ''
        SCSIController = ''
        DataStore = ''
        Type = ''
        StorageFormat = ''
    }
}


function Get-ServerInfo {
    [pscustomobject]@{
        ComputerName = ''
        OSInstallDate = ''
        UACSettings = ''
        LastBootupTime = ''
        Manufacturer = ''
        Model = ''
        Serial = ''
        OS = ''
        OSServicePack = ''
        PageFileBaseSize = ''
        PageFileMaxSize = ''
        PageFileMaxUse = ''
        IPv6DisabledComponents = ''
    }
}

function Get-ServiceInfo {
    [pscustomobject]@{
        ComputerName = ''
        Name = ''
        Caption = ''
        StartName = ''
        StartMode = ''
        State = ''
        PathName = ''
        DesktopInteract = ''
    }
}
function Get-ADComputer {
    [pscustomobject]@{
        AIDBHostName = 'dc01.ad.contoso.com'
        DNSHostname = 'dc01.ad.contoso.com'
        Name = 'dc01'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc01'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        AIDBHostName = 'dc02.ad.contoso.com'
        DNSHostname = 'dc02.ad.contoso.com'
        Name = 'dc02'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc02'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        AIDBHostName = 'cfgmgmt01.ad.contoso.com'
        DNSHostname = 'cfgmgmt01.ad.contoso.com'
        Name = 'cfgmgmt01'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/cfgmgmt01'
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        AIDBHostName = 'psbot01.ad.contoso.com'
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
                AIDBHostName = 'dc01.ad.contoso.com'
                certname = 'dc01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog", "roles::service::msadds"]'
            }
        }
        'dc02.ad.contoso.com' {
            [pscustomobject]@{
                AIDBHostName = 'dc02.ad.contoso.com'
                certname = 'dc02.ad.contoso.com'
                environment = 'wframe/winlogbeat'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::winlogbeat", "roles::service::msadds"]'
            }
        }
        'cfgmgmt01.ad.contoso.com' {
            [pscustomobject]@{
                AIDBHostName = 'cfgmgmt01.ad.contoso.com'
                certname = 'cfgmgmt01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog"]'
            }
        }
        'gitlab01.ad.contoso.com' {
            [pscustomobject]@{
                AIDBHostName = 'gitlab01.ad.contoso.com'
                certname = 'gitlab01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "roles::service::gitlab"]'
            }
        }
        'psbot01.ad.contoso.com' {
            [pscustomobject]@{
                AIDBHostName = 'psbot01.ad.contoso.com'
                certname = 'psbot01.ad.contoso.com'
                environment = 'production'
                puppet_classes = '["default", "nagios::base", "nagios::client", "profiles::base", "profiles::service::nxlog", "roles::psbot"]'
            }
        }
    }
}

function Get-ADUser {
    [pscustomobject]@{
        samaccountname = 'wframe'
        userprincipalname = 'wframe@ad.contoso.com'
        title = 'sysadmin'
        mail = 'wframe@contoso.com'
        sid = 'S-1-5-21-1004336348-1177238915-682003330-11111'
        distinguishedname = 'CN=wframe,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=computer-admin-psbot01,OU=groups,OU=tier 1,DC=ad,DC=contoso,DC=com', 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=psbot-users,OU=Domain Groups,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now
    },
    [pscustomobject]@{
        samaccountname = 'wframet0'
        userprincipalname = 'wframet0@ad.contoso.com'
        title = 'sysadmin'
        mail = ''
        sid = 'S-1-5-21-1004336348-1177238915-682003330-22222'
        distinguishedname = 'CN=wframet0,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=Domain Admins,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now
    }
}

function Get-ADGroup {
    [pscustomobject]@{
        samaccountname = 'domain admins'
        name = 'domain admins'
        distinguishedname = 'CN=Domain Admins,CN=Users,DC=ad,DC=contoso,DC=com'
        SID = 'S-1-5-21-1004336348-1177238915-682003330-512'
    },
    [pscustomobject]@{
        samaccountname = 'domain users'
        name = 'domain users'
        distinguishedname = 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com'
        SID = 'S-1-5-21-1004336348-1177238915-682003330-513'
    },
    [pscustomobject]@{
        samaccountname = 'computer-admin-psbot01'
        name = 'computer-admin-psbot01'
        distinguishedname = 'CN=computer-admin-psbot01,OU=groups,OU=tier 1,DC=ad,DC=contoso,DC=com'
        SID = 'S-1-5-21-1004336348-1177238915-682003330-111111'
    },
    [pscustomobject]@{
        samaccountname = 'psbot-users'
        name = 'psbot-users'
        distinguishedname = 'CN=psbot-users,OU=Domain Groups,DC=ad,DC=contoso,DC=com'
        SID = 'S-1-5-21-1004336348-1177238915-682003330-222222'
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

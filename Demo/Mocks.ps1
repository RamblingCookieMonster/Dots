function Get-ADComputer {
    [pscustomobject]@{
        DNSHostname = 'dc01.ad.contoso.com'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc01'
    },
    [pscustomobject]@{
        DNSHostname = 'dc02.ad.contoso.com'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/dc02'
    },
    [pscustomobject]@{
        DNSHostname = 'cfgmgmt01.ad.contoso.com'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 0/computers/cfgmgmt01'
    },
    [pscustomobject]@{
        DNSHostname = 'gitlab01.ad.contoso.com Datacenter'
        OperatingSystem = ''
        OperatingSystemVersion = ''
        CanonicalName = ''
    },
    [pscustomobject]@{
        DNSHostname = 'psbot01.ad.contoso.com'
        OperatingSystem = 'Windows Server 2016 Datacenter'
        OperatingSystemVersion = '10.0 (14393)'
        CanonicalName = 'ad.contoso.com/tier 1/computers/psbot01'
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
                certname = 'dc01.ad.contoso.com'
                environment = 'production'
                puppet_classes = 'default,nagios::base,nagios::client,profiles::base,profiles::service::nxlog,roles::service::msadds'
            }
        }
        'dc02.ad.contoso.com' {
            [pscustomobject]@{
                certname = 'dc02.ad.contoso.com'
                environment = 'wframe/winlogbeat'
                puppet_classes = 'default,nagios::base,nagios::client,profiles::base,profiles::service::winlogbeat,roles::service::msadds'
            }
        }
        'cfgmgmt01.ad.contoso.com' {
            [pscustomobject]@{
                certname = 'cfgmgmt01.ad.contoso.com'
                environment = 'production'
                puppet_classes = 'default,nagios::base,nagios::client,profiles::base,profiles::service::nxlog'
            }
        }
        'gitlab01.ad.contoso.com' {
            [pscustomobject]@{
                certname = 'gitlab01.ad.contoso.com'
                environment = 'production'
                puppet_classes = 'default,nagios::base,nagios::client,profiles::base,roles::service::gitlab'
            }
        }
        'psbot01.ad.contoso.com' {
            [pscustomobject]@{
                certname = 'psbot01.ad.contoso.com'
                environment = 'production'
                puppet_classes = 'default,nagios::base,nagios::client,profiles::base,profiles::service::nxlog,roles::psbot'
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
        lastlogondate = [datetime]::Now()
    },
    [pscustomobject]@{
        samaccountname = 'wframet0'
        userprincipalname = 'wframet0@ad.contoso.com'
        title = 'sysadmin'
        mail = ''
        sid = 'S-1-5-21-1004336348-1177238915-682003330-22222'
        distinguishedname = 'CN=wframet0,OU=Domain Users,DC=ad,DC=contoso,DC=com'
        memberof = @('CN=Domain Admins,CN=Users,DC=ad,DC=contoso,DC=com', 'CN=Domain Users,CN=Users,DC=ad,DC=contoso,DC=com')
        lastlogondate = [datetime]::Now()
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
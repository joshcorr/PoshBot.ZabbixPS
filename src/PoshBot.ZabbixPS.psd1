@{
RootModule = 'PoshBot.ZabbixPS.psm1'
ModuleVersion = '0.0.2'
GUID = '33a63414-5bcb-4df8-8b51-f43f02c62f50'
Author = 'Josh Corrick (@joshcorr)'
CompanyName = 'blog.corrick.io'
Copyright = '(c) 2021 Josh Corrick (@joshcorr). All rights reserved.'
Description = 'Interact with Zabbix via PoshBot'
PowerShellVersion = '5.0.1'
RequiredModules = @(@{ModuleName ='PoshBot'; ModuleVersion = '0.13.0'},@{ModuleName = 'ZabbixPS'; ModuleVersion = '0.1.8' })
FunctionsToExport = @('convertFromUnixTimeStamp','convertToUnixTimeStamp','getZabbixProblem','getZabbixMaintenance','getZabbixHostInMaintenance','acknowledgeZabbixEvent')
CmdletsToExport = @()
VariablesToExport = @()
AliasesToExport = @()
PrivateData = @{
	Permissions = @(
            @{
                Name = 'Read'
                Description = 'Can run all Get commands'
            }
            @{
                Name = 'Write'
                Description = 'Can run all Set, Write, Update commands'
            }
            @{
                Name = 'Execute'
                Description = 'Can run all Invoke, Start commands'
            }
        )
        PSData = @{
            Tags = @('PoshBot','ChatOps','Zabbix')
            LicenseUri = 'https://raw.githubusercontent.com/joshcorr/PoshBot.ZabbixPS/main/LICENSE'
            ProjectUri = 'https://github.com/joshcorr/PoshBot.ZabbixPS'
            ReleaseNotes = 'https://raw.githubusercontent.com/joshcorr/PoshBot.ZabbixPS/main/CHANGELOG.md'
            # Prerelease = ''
        }
    }
}

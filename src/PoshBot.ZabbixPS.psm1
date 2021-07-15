#Functions written below:
function convertFromUnixTimeStamp {
    <#
    .SYNOPSIS
        PoshBot function to convert from UnixTimeStamp
    .PARAMETER timestamp
        A number in seconds counting up from epoch (01/01/1970)
    .PARAMETER format
        A number to pull the specific format from the getDateTimeFormats array
    .EXAMPLE
        !unitxtime [-timestamp <timeinseconds> -format <number>]
    #>
    [PoshBot.BotCommand(
        CommandName = 'convertFromUnixTimeStamp',
        Aliases = ('unixtime', 'fromunixtime')
    )]
    [CmdletBinding()]
    param (
        [int64]$timeStamp,
        [int]$format
    )
    if ($format) {
        [DateTimeOffset]::FromUnixTimeSeconds($timeStamp).DateTime.GetDateTimeFormats()[$format]
    } else {
        [DateTimeOffset]::FromUnixTimeSeconds($timeStamp).DateTime
    }
}
function convertToUnixTimeStamp {
    <#
    .SYNOPSIS
        PoshBot function to convert to UnixTimeStamp
    .PARAMETER date
        A string in the format MM/dd/YYYY
    .EXAMPLE
        !tounixtime [-date <string >]
    #>
    [PoshBot.BotCommand(
        CommandName = 'convertToUnixTimeStamp',
        Aliases = ('tounixtime')
    )]
    [CmdletBinding()]
    param (
        [string]$date
    )
    try {
        $validdate = [DateTimeOffset]::ParseExact($date, 'd', $null).ToUnixTimeSeconds()
        # following line ensures local time is returned since .ToUnixTimeSeconds() is UTC
        $hours = [DateTimeOffset]::ParseExact($date, 'd', $null).Offset.TotalSeconds
        $validdate + $hours
    } catch {
        New-PoshBotCardResponse -Type Warning -Text 'Please use the format MM/dd/Year'
    }
}

function getZabbixProblem {
    <#
    .SYNOPSIS
        PoshBot function to return Zabbix Problems
    .EXAMPLE
        !GetZabbixProblem [-instance [FriendlyName] -time ['today','yesterday','thisweek','alltime']]
    #>
    [PoshBot.BotCommand(
        CommandName = 'GetZabbixProblem',
        Aliases = 'GetZBXProblem',
        Permissions = ('Read')
    )]
    [CmdletBinding()]
    param (
        [PoshBot.FromConfig('ZabbixAPI')]
        # ZabbixAPI credential
        [Parameter(Mandatory)]
        [pscredential]$creds,
        [PoshBot.FromConfig('InstanceData')]
        # FQDN to the Zabbix API in KV pair
        [Parameter(Mandatory)]
        [hashtable]$InstanceData,
        # Instance friendly name filter
        [Parameter()]
        [string]$Instance,
        # Time filter for problems
        [Parameter()]
        [validateSet('today', 'yesterday', 'thisweek', 'alltime')]
        [string]$time = 'today'
    )
    if ($Instance) {
        $InstanceURL = $InstanceData.GetEnumerator() | Where-Object {$_.key -eq $Instance}
    } else {
        $InstanceURL = $InstanceData.GetEnumerator()
    }
    foreach ($i in $InstanceURL) {
        $session = New-ZBXSession -Name "Temp-PoshBot" -URI $i.Value -Credential $creds
        switch ($time) {
            'today' {$timeFilter = convertToUnixTimeStamp -date (Get-Date).GetDateTimeFormats()[3]}
            'yesterday' {$timeFilter = convertToUnixTimeStamp -date (Get-Date).AddDays(-1).GetDateTimeFormats()[3]}
            'thisweek' {$timeFilter = convertToUnixTimeStamp -date (Get-Date).AddDays(-7).GetDateTimeFormats()[3]}
            'alltime' {$timeFilter = 0}
        }

        try {
            $problems = Get-ZBXProblem -Session $session | Where-Object {$_.clock -ge $timeFilter} | Sort-Object -Property clock
            if ($null -ne $problems) {
                foreach ($p in $problems) {
                    $eventdata = Get-ZBXEvent -Session $session -EventID $($p.eventid)
                    $friendlyTime = convertFromUnixTimeStamp -timestamp $($p.clock) -format 105

                    $fields = [ordered]@{
                        Host         = $($eventdata.hosts.name)
                        EventID      = $p.eventid
                        Problem      = $p.name
                        Time         = $friendlyTime
                        Acknowledged = $(if ($p.acknowledged -eq 1) {'yes'} else {'no'})
                    }
                    if ($fields.acknowledged -eq 'yes') {
                        New-PoshBotCardResponse -type Normal -Title "Zabbix Problems on [$($i.Key)] from [$time]" -fields $fields
                    } else {
                        New-PoshBotCardResponse -type Warning -Title "Zabbix Problems on [$($i.Key)] from [$time]" -fields $fields
                    }
                }
            } else {
                New-PoshBotCardResponse -Title "Zabbix Problems on [$($i.Key)] from [$time]" -Text "Currently no active or unacknowledged problems on [$($i.Key)]"
            }
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Something bad happened while running !$($MyInvocation.MyCommand.Name) against [$($i.Key)]"
        } finally {
            $null = Remove-ZBXSession $session.id
            $Global:_ZabbixAuthenticationToken, $Global:_ZabbixSessions = $null
        }
    }
}
function getZabbixHostInMaintenance {
    <#
    .SYNOPSIS
        PoshBot function to return Zabbix Maintenance
    .EXAMPLE
        !GetZabbixHostInMaintenance [-instance [FriendlyName] -hostname [hostname]]
    #>
    [PoshBot.BotCommand(
        CommandName = 'GetZabbixHostInMaintenance',
        Aliases = ('GetZBXHostMaint', 'GetZBXHostMaintenance'),
        Permissions = ('Read')
    )]
    [CmdletBinding()]
    param (
        [PoshBot.FromConfig('ZabbixAPI')]
        # ZabbixAPI credential
        [Parameter(Mandatory)]
        [pscredential]$creds,
        [PoshBot.FromConfig('InstanceData')]
        # FQDN to the Zabbix API in KV pair
        [Parameter(Mandatory)]
        [hashtable]$InstanceData,
        # Instance friendly name filter
        [Parameter()]
        [string]$Instance,
        # Hostname specifically looking for
        [Parameter()]
        [string]$HostName
    )
    if ($Instance) {
        $InstanceURL = $InstanceData.GetEnumerator() | Where-Object {$_.key -eq $Instance}
    } else {
        $InstanceURL = $InstanceData.GetEnumerator()
    }
    $HostSplat = @{name = $HostName}
    foreach ($i in $InstanceURL) {
        $session = New-ZBXSession -Name "Temp-PoshBot" -URI $i.Value -Credential $creds
        try {
            # Filtering for hosts with Active Maintenance and Actively monitored
            # If hostsplat is not null lookup specific host
            $hosts = Get-ZBXHost -Session $session @HostSplat | Where-Object {$_.maintenance_status -eq 1 -and $_.status -eq 0}
            if ($null -ne $hosts) {
                foreach ($h in $hosts) {
                    $m = Get-ZBXMaintenance -Session $Session -id $h.maintenanceID

                    $fields = [ordered]@{
                        Name                 = $($h.name)
                        MaintenanceID        = $($h.maintenanceID)
                        MaintenanceName      = $($m.name)
                        MaintenanceFrom   = $(convertFromUnixTimeStamp -timestamp $($h.maintenance_from) -format 105)
                    }

                    New-PoshBotCardResponse -type Normal -Title "Zabbix Hosts in Maintenance on [$($i.Key)]" -fields $fields
                }
            } else {
                New-PoshBotCardResponse -Type Warning  -Title "Zabbix Hosts not found in Maintenance on [$($i.Key)]" -Text "Check Zabbix [$($i.key)] to ensure this is expected"
            }
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Something bad happened while running !$($MyInvocation.MyCommand.Name) against [$($i.Key)]"
        } finally {
            $null = Remove-ZBXSession $session.id
            $Global:_ZabbixAuthenticationToken, $Global:_ZabbixSessions = $null
        }
    }
}
function getZabbixMaintenance {
    <#
    .SYNOPSIS
        PoshBot function to return Zabbix Maintenance
    .EXAMPLE
        !GetZabbixMaintenance [-instance [FriendlyName]]
    #>
    [PoshBot.BotCommand(
        CommandName = 'GetZabbixMaintenance',
        Aliases = ('GetZBXMaint', 'GetZBXMaintenance'),
        Permissions = ('Read')
    )]
    [CmdletBinding()]
    param (
        [PoshBot.FromConfig('ZabbixAPI')]
        # ZabbixAPI credential
        [Parameter(Mandatory)]
        [pscredential]$creds,
        [PoshBot.FromConfig('InstanceData')]
        # FQDN to the Zabbix API in KV pair
        [Parameter(Mandatory)]
        [hashtable]$InstanceData,
        # Instance friendly name filter
        [Parameter()]
        [string]$Instance
    )
    if ($Instance) {
        $InstanceURL = $InstanceData.GetEnumerator() | Where-Object {$_.key -eq $Instance}
    } else {
        $InstanceURL = $InstanceData.GetEnumerator()
    }
    foreach ($i in $InstanceURL) {
        $session = New-ZBXSession -Name "Temp-PoshBot" -URI $i.Value -Credential $creds

        try {
            $MaintenanceWindow = Get-ZBXMaintenance -Session $session
            if ($null -ne $MaintenanceWindow) {
                foreach ($m in $MaintenanceWindow) {
                    $maintStart = [timespan]::FromSeconds($m.timeperiods.start_time).totalhours
                    $maintDurration = [timespan]::FromSeconds($m.timeperiods.period).totalhours
                    $maintEnd = $maintStart + $maintDurration
                    $currentdate = (Get-Date)
                    $currentHour = $($currentdate.Hour + ($currentdate.Minute / 60))

                    $fields = [ordered]@{
                        Name                 = $($m.name)
                        Description          = $($m.Description)
                        ActiveSince          = $(convertFromUnixTimeStamp -timestamp $($m.active_since) -format 105)
                        ActiveUntil          = $(convertFromUnixTimeStamp -timestamp $($m.active_till) -format 105)
                        MaintenanceType      = $(switch ($m.timeperiods.timeperiod_type) { 0 {"one time only"}; 2 {"daily"}; 3 {"weekly"}; 4 {"monthly"}; default {"notsure"} })
                        MaintenanceStart     = $maintStart
                        MaintenanceEnd       = $maintEnd
                        MaintenanceDurration = "$($maintDurration) HRs"
                        Active               = $(if ($currentHour -gt $maintStart -and $currentHour -lt $maintEnd) {"Possibly - Day Needs to be calculated"}else {"No"})
                    }

                    New-PoshBotCardResponse -type Normal -Title "Zabbix Maintenance Schedules on [$($i.Key)]" -fields $fields
                }
            } else {
                New-PoshBotCardResponse -Type Warning  -Title "Zabbix Maintenance not found on [$($i.Key)]" -Text "Check Zabbix [$($i.key)] to ensure this is expected"
            }
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Something bad happened while running !$($MyInvocation.MyCommand.Name) against [$($i.Key)]"
        } finally {
            $null = Remove-ZBXSession $session.id
            $Global:_ZabbixAuthenticationToken, $Global:_ZabbixSessions = $null
        }
    }
}
function acknowledgeZabbixEvent {
    <#
    .SYNOPSIS
        PoshBot function to acknowledge a Zabbix Event
    .EXAMPLE
        !AcknowledgeZabbixEvent [-instance [FriendlyName] -eventid <string> -message "<string>"]
    #>
    [PoshBot.BotCommand(
        CommandName = 'AcknowledgeZabbixEvent',
        Aliases = ('AckZBX'),
        Permissions = ('Write')
    )]
    [CmdletBinding()]
    param (
        [PoshBot.FromConfig('ZabbixAPI')]
        # ZabbixAPI credential
        [Parameter(Mandatory)]
        [pscredential]$creds,
        [PoshBot.FromConfig('InstanceData')]
        # FQDN to the Zabbix API in KV pair
        [Parameter(Mandatory)]
        [hashtable]$InstanceData,
        # Instance friendly name filter
        [Parameter()]
        [string]$Instance,
        # EventID of the problem you are acknowledging
        [Parameter()]
        [string]$eventid,
        # Message of the acknowledgement message
        [Parameter()]
        [string]$message
    )
    if ($Instance) {
        $InstanceURL = $InstanceData.GetEnumerator() | Where-Object {$_.key -eq $Instance}
    } else {
        $InstanceURL = $InstanceData.GetEnumerator()
    }
    foreach ($i in $InstanceURL) {
        $session = New-ZBXSession -Name "Temp-PoshBot" -URI $i.Value -Credential $creds
        $user = $global:PoshBotContext.FromName
        if ($PSBoundParameters.ContainsKey('message')) {
            $AcknowledgeMessage = $message + "- $user"
        } else {
            $AcknowledgeMessage = "Message Acknolwedged via PoshBot by $user"
        }
        try {
            $output = Confirm-ZBXEvent -Session $session -EventID $eventid -AcknowledgeAction Acknowledge, AddMessage -AcknowledgeMessage $AcknowledgeMessage
            New-PoshBotCardResponse -Title "Zabbix Acknowledged on [$($i.Key)] for [$eventid]" -Text ($output | Format-List -Property * | Out-String)
        } catch {
            New-PoshBotCardResponse -Type Error -Text "Something bad happened while running !$($MyInvocation.MyCommand.Name) against [$($i.Key)]"
        } finally {
            $null = Remove-ZBXSession $session.id
            $Global:_ZabbixAuthenticationToken, $Global:_ZabbixSessions = $null
        }
    }
}

# Export all functions for poshbot
Export-ModuleMember *



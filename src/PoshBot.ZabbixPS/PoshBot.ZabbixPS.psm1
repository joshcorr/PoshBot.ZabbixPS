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
    .NOTES
        Uses code from https://stackoverflow.com/questions/10781697/convert-unix-time-with-powershell
    #>
    [PoshBot.BotCommand(
        CommandName = 'convertFromUnixTimeStamp',
        Aliases = ('unixtime','fromunixtime')
    )]
    [CmdletBinding()]
    param (
        [int64]$timeStamp,
        [int]$format
    )
    $epoch = (Get-Date "01/01/1970")
    if ($format){
        $epoch.AddSeconds($timeStamp).GetDateTimeFormats()[$format]
    } else {
        $epoch.AddSeconds($timeStamp)
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
    .NOTES
        Uses ideas from:
        https://www.powershellmagazine.com/2013/07/09/pstip-how-to-check-if-a-datetime-string-is-in-a-specific-pattern/
        https://stackoverflow.com/questions/4192971/in-powershell-how-do-i-convert-datetime-to-unix-time/
    #>
    [PoshBot.BotCommand(
        CommandName = 'convertToUnixTimeStamp',
        Aliases = ('tounixtime')
    )]
    [CmdletBinding()]
    param (
        [string]$date
    )
    try { $validdate = [datetime]::ParseExact($date,'d',$null)
    $epoch = (Get-Date "01/01/1970")
    (New-TimeSpan -Start $epoch -End (Get-Date $validdate).date).TotalSeconds
    } catch {
        New-PoshBotCardResponse -Type Warning -Text 'Please use the format MM/dd/Year'
    }
}

function getZabbixProblem {
    <#
    .SYNOPSIS
        PoshBot function to return Zabbix Problems
    .EXAMPLE
        !GetZabbixProblem [-instance [FQDN] -time ['today','yesterday','thisweek','alltime']]
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
        [PoshBot.FromConfig('Instance')]
        # FQDN to the Zabbix API
        [Parameter(Mandatory)]
        [string]$Instance,
        [Parameter()]
        [validateSet('today','yesterday','thisweek','alltime')]
        [string]$time = 'today'
    )

    $session = New-ZBXSession -Name "Temp-PoshBot" -URI $Instance -Credential $creds
    switch ($time) {
        'today'     {$timeFilter = convertToUnixTimeStamp -date (Get-Date).GetDateTimeFormats()[3]}
        'yesterday' {$timeFilter = convertToUnixTimeStamp -date (Get-Date).AddDays(-1).GetDateTimeFormats()[3]}
        'thisweek'  {$timeFilter = convertToUnixTimeStamp -date (Get-Date).AddDays(-7).GetDateTimeFormats()[3]}
        'alltime'   {$timeFilter = 0}
    }

    try {
        $problems = Get-ZBXProblem -Session $session | Where-Object {$_.clock -ge $timeFilter} | Sort-Object -Property clock
        if ($null -ne $problems) {
            foreach ($p in $problems) {
                $eventdata = Get-ZBXEvent -Session -EventID $($p.eventid)
                $friendlyTime = convertFromUnixTimeStamp -timestamp $($p.clock) -format 105

                $fields = [ordered]@{
                    Host = $($eventdata.hosts.name)
                    EventID = $p.eventid
                    Problem = $p.name
                    Time = $friendlyTime
                    Acknowledged = $(if($p.acknowledged -eq 1){'yes'} else {'no'})
                }
                if ($fields.acknowledged -eq 'yes') {
                    New-PoshBotCardResponse -type Normal -Title "Zabbix Problems on [$instance] from [$time]" -fields $fields
                } else {
                    New-PoshBotCardResponse -type Warning -Title "Zabbix Problems on [$instance] from [$time]" -fields $fields
                }
            }
        } else {
            New-PoshBotCardResponse -Title "Zabbix Problems on [$instance] from [$time]" -Text "Currently no active or unacknowledged problems on [$instance]"
        }
    } catch {
        New-PoshBotCardResponse -Type Error -Text "Something bad happened while running !$($MyInvocation.MyCommand.Name)"
    } finally {
        $null = Remove-ZBXSession $session.id
    }
}

# Export all functions for poshbot
Export-ModuleMember *



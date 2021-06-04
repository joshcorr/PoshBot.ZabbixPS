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


# Export all functions for poshbot
Export-ModuleMember *



BeforeDiscovery {
    $s = [io.path]::DirectorySeparatorChar
    $ModulePath = $PSScriptRoot, '..' -join $s
    $Folder = (Get-Item $ModulePath).FullName
    $File = ($PSCommandPath).Replace('.Tests.ps1','.psd1').Split($s)[-1]
    $ModuleName = ($PSCommandPath).Replace('.Tests.ps1','').Split($s)[-1]
    $Path = $Folder, 'src', $File -join $s
    Import-Module $Path
    $Manifest = Test-ModuleManifest -Path $Path
    $Commands = $Manifest.ExportedFunctions.keys | Where-Object {$null -ne $PSItem}

}
AfterAll {
    $ModuleName = ($PSCommandPath).Replace('.Tests.ps1','').Split($s)[-1]
    Remove-Module -Name $ModuleName -Force -ErrorAction SilentlyContinue
}
describe "Module loading" {
    It "Should load the module" {
        Get-Module -Name 'PoshBot.ZabbixPS' | Should -Not -Be $null
    }
    It "Should have <_> function loaded" -foreach $Commands {
        (Get-Command -Name $PSItem).Name | Should -Be $PSItem
    }
}
describe "Code Coverage" {
    It "Should convertToUnixTimeStamp "{
        convertToUnixTimeStamp -date ([datetime]::Now.ToString('d')) | Should -Be (([DateTimeOffset]::ParseExact([datetime]::Now.ToString('d'),'d',$null).ToUnixTimeSeconds() + [DateTimeOffset]::ParseExact([datetime]::Now.ToString('d'),'d',$null).Offset.TotalSeconds) )
    }
    It "Should convertFromUnixTimeStamp "{
        convertFromUnixTimeStamp -timeStamp ([DateTimeOffset]::Now.ToUnixTimeSeconds()) | Should -BeLessOrEqual ([DateTimeOffset]::Now.UtcDateTime )
    }
    It "Should convertFromUnixTimeStamp with format"{
        convertFromUnixTimeStamp -timeStamp ([DateTimeOffset]::Now.ToUnixTimeSeconds()) -format 105 | Should -BeLessOrEqual ([DateTimeOffset]::Now.UtcDateTime).GetDateTimeFormats()[105]
    }
}
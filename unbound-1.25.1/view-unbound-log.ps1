# Converts Unbound log timestamps to LOCAL time (compatible with PS 2.0+)

param(
    [string]$LogPath = "$PSScriptRoot\unbound.log",
    [int]$Lines = 100
)

if (-not (Test-Path $LogPath)) {
    Write-Error "Log file not found: $LogPath"
    exit 1
}

# Unix epoch start (always UTC)
$epochStart = [datetime]::new(1970, 1, 1, 0, 0, 0, [datetimekind]::Utc)
Write-Host CurrentDirectory
[System.Environment]::CurrentDirectory
Write-Host Path
(Get-Location).Path

$outputCodePage = [Console]::OutputEncoding.CodePage
Write-Host Console CodePage $outputCodePage
Write-Host chcp
chcp

# Source - https://stackoverflow.com/a/57134096
# Posted by mklement0, modified by community. See post 'Timeline' for change history
# Retrieved 2026-06-10, License - CC BY-SA 4.0

$OutputEncoding = [console]::InputEncoding = [console]::OutputEncoding = New-Object System.Text.UTF8Encoding
Write-Host OutputEncoding $OutputEncoding

$outputCodePage = [Console]::OutputEncoding.CodePage
Write-Host Now Console CodePage $outputCodePage

Write-Host "`n🪵 Unbound Log (Last $Lines lines, LOCAL time):" -ForegroundColor Cyan -BackgroundColor DarkGray
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray

Get-Content $LogPath -Tail $Lines | ForEach-Object {
    # Match [10-digit Unix timestamp] pattern
    if ($_ -match '^(\[)(\d{10})(\].*)$') {
        $epochSeconds = [Int64]$Matches[2]
        $utcTime = $epochStart.AddSeconds($epochSeconds)
        $localTime = $utcTime.ToLocalTime()
        $timeStr = $localTime.ToString("yyyy-MM-dd HH:mm:ss")

        # Color by severity
        $color = "White"
        if ($_ -match "error|fail|bogus|NXDOMAIN") { $color = "Red" }
        elseif ($_ -match "warn|reject") { $color = "Yellow" }
        elseif ($_ -match "notice|reply from") { $color = "Cyan" }
        elseif ($_ -match "validated|answer from") { $color = "Green" }

        $line = $_ -replace '\[\d{10}\]', "[$timeStr]"
        Write-Host $line -ForegroundColor $color
    } else {
        Write-Host $_
    }
}
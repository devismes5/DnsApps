# Run as
# powershell -ExecutionPolicy Bypass -File unbound-log-viewer.ps1
# or pipe it directly to more:
# powershell -File unbound-log-viewer.ps1 | more
#
# Path to Unbound log
# Converts Unbound log timestamps (Unix epoch UTC) to LOCAL time

param(
    [string]$LogPath = "C:\Users\Bruno\LocalDnsApps\unbound\unbound.log",
    [int]$Lines = 50  # Last N lines
)

if (-not (Test-Path $LogPath)) {
    Write-Error "Log file not found: $LogPath"
    exit 1
}

Write-Host "`n🪵 Unbound Log (Last $Lines lines, LOCAL time):" -ForegroundColor Cyan -BackgroundColor DarkGray
Write-Host "────────────────────────────────────────────────────────────" -ForegroundColor Gray

Get-Content $LogPath -Tail $Lines | ForEach-Object {
    # Try to match [timestamp] pattern
    if ($_ -match '^(\[)(\d{10})(\].*)$') {
        $epoch = [Int64]$Matches[2]
        $localTime = (Get-Date -Date "1970-01-01 00:00:00Z" -Kind Utc).AddSeconds($epoch).ToLocalTime()
        $timeStr = $localTime.ToString("yyyy-MM-dd HH:mm:ss")

        # Color-code by severity
        if ($_ -match "error|fail|bogus") { $color = "Red" }
        elseif ($_ -match "warn") { $color = "Yellow" }
        elseif ($_ -match "notice") { $color = "Cyan" }
        else { $color = "White" }

        # Replace [1234567890] with [YYYY-MM-DD HH:MM:SS]
        $line = $_ -replace '\[\d{10}\]', "[$timeStr]"
        Write-Host $line -ForegroundColor $color
    } else {
        Write-Host $_
    }
}
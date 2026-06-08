# Run as
# powershell -ExecutionPolicy Bypass -File unbound-log-viewer.ps1
# or pipe it directly to more:
# powershell -File unbound-log-viewer.ps1 | more
#
# Path to Unbound log
$logPath = "C:\Users\Bruno\LocalDnsApps\unbound\unbound.log"
if (-not (Test-Path $logPath)) {
    Write-Error "Log file not found: $logPath"
    exit
}

# Read log, convert timestamps
Get-Content $logPath | ForEach-Object {
    if ($_ -match '^(\[)(\d+)(\].*)$') {
        $timestamp = [Int64]$Matches[2]
        $humanTime = (Get-Date "1970-01-01 00:00:00").AddSeconds($timestamp).ToString("yyyy-MM-dd HH:mm:ss")
        $_ -replace '\[\d+\]', "[$humanTime]"
    } else {
        $_
    }
}
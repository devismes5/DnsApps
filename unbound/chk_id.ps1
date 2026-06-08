Get-WinEvent -FilterHashtable @{
    LogName      = 'System'
    StartTime    = (Get-Date).AddDays(-8)
    ProviderName = 'Service Control Manager'
	Properties[0] = 'DNSCrypt client proxy'
} -MaxEvents 20 | ForEach-Object {
    $i = 0
    Write-Host "--- Id: $($_.Id) | Time: $($_.TimeCreated) ---"
    $_.Properties | ForEach-Object {
        Write-Host "Properties[$i]: $($_.Value)"
        $i++
    }
    Write-Host ""  # blank line between events
}
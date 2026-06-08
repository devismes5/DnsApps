Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id      = 7036
	ProviderName = 'Service Control Manager'
	StartTime = (Get-Date).AddDays(-7)
} -MaxEvents 5 | ForEach-Object {
    $i = 0
    $_.Properties | ForEach-Object {
        Write-Host "Properties[$i]: $($_.Value)"
        $i++
    }
}
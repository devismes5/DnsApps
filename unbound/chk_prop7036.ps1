Get-WinEvent -FilterHashtable @{
    LogName      = 'System'
	StartTime    = (Get-Date).AddDays(-8)
    ProviderName = 'Service Control Manager'
}| ForEach-Object {
    $i = 0
	Write-Host "Id: $($Id.Value)"
    $_.Properties | ForEach-Object {
        Write-Host "Properties[$i]: $($_.Value)"
        $i++
    }
}
#    Id           = 7036
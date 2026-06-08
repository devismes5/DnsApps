# Filter by log, event ID and time in one go
Get-WinEvent -FilterHashtable @{
    LogName   = 'System'
    Id        = 7036
	ProviderName = 'Service Control Manager'
    StartTime = (Get-Date).AddDays(-1)
} | Select-Object TimeCreated, Id, ProviderName,
    @{Name='ServiceName'; Expression={ $_.Properties[0].Value }},
    @{Name='State';       Expression={ $_.Properties[1].Value }} |
    Format-List	

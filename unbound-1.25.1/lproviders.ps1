# Check what providers are logging Event ID 7036, without any name filter
Get-WinEvent -FilterHashtable @{
    LogName = 'System'
    Id      = 7036
} -MaxEvents 60 | Select-Object ProviderName -Unique
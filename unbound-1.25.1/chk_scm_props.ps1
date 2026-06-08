# No time restriction - just find ANY 7036 from SCM
Get-WinEvent -FilterHashtable @{
    LogName      = 'System'
    Id           = 7034
} -MaxEvents 5 | Select-Object TimeCreated, ProviderName,
    @{Name='P0'; Expression={ $_.Properties[0].Value }},
    @{Name='P1'; Expression={ $_.Properties[1].Value }} |
    Format-List
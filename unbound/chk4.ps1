Get-WinEvent -FilterHashtable @{
    LogName      = 'System'
    ProviderName = 'Service Control Manager'
    StartTime    = (Get-Date).AddMinutes(-5)
} | Where-Object { $_.Properties[0].Value -eq 'DNSCrypt client proxy' } |
    Select-Object TimeCreated, Id,
        @{Name='ServiceName'; Expression={ $_.Properties[0].Value }},
        @{Name='P1';          Expression={ $_.Properties[1].Value }} |
    Format-List
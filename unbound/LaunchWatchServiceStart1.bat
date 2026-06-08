# Full debug script (run in *Elevated* PowerShell)
$Path = "C:\Users\Bruno\LocalDnsApps\unbound\WatchServiceStart.mof"
# MOF content (with #PRAGMA AUTORECOVER)
$Mof = @'
// Put at top — forces correct namespace (even if mofcomp ignores it, better than nothing)
#pragma namespace("\\\\.\\root\\subscription")
#pragma autorecover

instance of __EventFilter as $MyFilter
{
    Name = "Watch_ServiceStart_dnscrypt-proxy";
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 5 WHERE TargetInstance ISA 'Win32_Service' AND TargetInstance.Name = 'dnscrypt-proxy' AND TargetInstance.State = 'Running'";
    QueryLanguage = "WQL";
};

instance of CommandLineEventConsumer as $MyConsumer
{
    Name = "Watch_ServiceStart_unbound";
    CommandLineTemplate = "C:\\Windows\\System32\\cmd.exe /c \"C:\\Users\\Bruno\\LocalDnsApps\\unbound\\restart-unbound.cmd\"";
    WorkingDirectory = "C:\\Users\\Bruno\\LocalDnsApps\\unbound";
};

instance of __FilterToConsumerBinding
{
    Filter = $MyFilter;
    Consumer = $MyConsumer;
};
'@

# Save with *no* encoding quirks (Unicode is still best, but try UTF8NoBOM if issues persist)
Set-Content -Path $Path -Value $Mof -Encoding Unicode -Force

Write-Host "✅ MOF saved. Now compiling..." -ForegroundColor Green
Write-Host "Running: mofcomp `"$Path`""
Write-Host ""

# Capture full output (including stderr)
$Result = & mofcomp $Path 2>&1
$Result | ForEach-Object { Write-Host $_ }

# Check exit code
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ mofcomp FAILED with exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Check Windows Event Viewer (Applications and Services Logs → Microsoft → Windows → WMI-Activity → Operational)" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ mofcomp reported success!" -ForegroundColor Green
}

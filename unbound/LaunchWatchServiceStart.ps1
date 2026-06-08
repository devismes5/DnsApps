# Full debug script (run in *Elevated* PowerShell)
# brusam, 3-6-2026
# See https://stackoverflow.com/questions/5466329/whats-the-best-way-to-determine-the-location-of-the-current-powershell-script
#
function Get-ScriptPath()
{
	Write-Host "PSVersion Major: $($PSVersionTable.PSVersion.Major)"
	if ($PSVersionTable.PSVersion.Major -ge 3)
    {
        return $PSScriptRoot
    }
    return [IO.Path]::GetDirectoryName($PSCommandPath)
}



$ScriptPath = Get-ScriptPath
Write-Host "ScriptPath $ScriptPath"

$Path = "$ScriptPath\WatchServiceStart.mof"

Write-Host "Running: mofcomp `"$Path`"" -ForegroundColor Green
Write-Host ""

# Capture full output (including stderr)
$Result = & mofcomp $Path > WatchServiceStart.out 2>&1
$Result | ForEach-Object { Write-Host $_ }

# Check exit code
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n❌ mofcomp FAILED with exit code: $LASTEXITCODE" -ForegroundColor Red
    Write-Host "Check Windows Event Viewer (Applications and Services Logs → Microsoft → Windows → WMI-Activity → Operational)" -ForegroundColor Yellow
} else {
    Write-Host "`n✅ mofcomp successful!" -ForegroundColor Green
}

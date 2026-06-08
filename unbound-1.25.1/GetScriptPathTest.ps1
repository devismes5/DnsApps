# Source - https://stackoverflow.com/a/65151437
# Posted by WayneC
# Retrieved 2026-06-03, License - CC BY-SA 4.0
. "$PSScriptRoot\\GetScriptPath.ps1"

$ScriptPath = Get-Script-Path
Write-Host "ScriptPath $ScriptPath"

if ($ScriptPath)
{
	Exit 0
} else {
	Exit 1
}

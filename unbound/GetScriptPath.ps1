# Function Get-Script-Path
# brusam, 3-6-2026
#
## Does not work in my PowerShell 3
function Get-Script-Directory
{
    $scriptInvocation = (Get-Variable MyInvocation -Scope 1).Value
    Split-Path $scriptInvocation.MyCommand.Path
}
function Get-Script-Path()
{
	Write-Host "ScriptPath from PSScriptRoot: $PSScriptRoot"
	# PSScriptRoot: C:\Users\Bruno\LocalDnsApps\unbound
	# PSScriptRoot: C:\Users\Bruno\LocalDnsApps\unbound\GetScriptPath.ps1

	$ScriptPath = (Get-Location).Path
	Write-Host "ScriptPath from Get-Location Path: $ScriptPath"
	# ScriptPath from Get-Location Path: C:\Users\Bruno\LocalDnsApps\unbound
	
	Write-Host "PSCommandPath: $PSCommandPath"
	# PSCommandPath: C:\Users\Bruno\LocalDnsApps\unbound\GetScriptPath.ps1

	$ScriptDirPath = Split-Path $MyInvocation.MyCommand.Path
	Write-Host "ScriptPath from MyCommand.Path: $ScriptDirPath"
	# PS2 idiom that does not work in PS3
	# ERR: Split-Path : Cannot bind argument to parameter 'Path' because it is null.
	#      At C:\Users\Bruno\LocalDnsApps\unbound\GetScriptPath.ps1:23 char:30
	# ScriptPath from MyCommand.Path:

	$ScriptPath = Split-Path -Parent $PSCommandPath
	Write-Host "ScriptPath from PSCommandPath Parent: $PSCommandPath"
	# ScriptPath from PSCommandPath Parent: C:\Users\Bruno\LocalDnsApps\unbound\LaunchWatchServiceStart.ps1

	$ScriptPath = [IO.Path]::GetDirectoryName($PSCommandPath)
	Write-Host "ScriptPath from GetDirectoryName: $ScriptPath"
	# ScriptPath from GetDirectoryName: C:\Users\Bruno\LocalDnsApps\unbound

	# The automatic variable $ExecutionContext is available from PowerShell 2 upwards.
	# | $ExecutionContext contains an EngineIntrinsics object that represents the execution context of the Windows PowerShell host. You can use this variable to find the execution objects that are available to cmdlets.
	# Write-Host "$ExecutionContext.SessionState.Path: $ExecutionContext.SessionState.Path"
	# System.Management.Automation.EngineIntrinsics.SessionState.Path
	# $ExecutionContext.SessionState.Path returns a System.Management.Automation.PathIntrinsics object
	Write-Host "SessionState.Path: $ExecutionContext.SessionState.Path"
	Write-Host "SessionState.Path.CurrentLocation: $ExecutionContext.SessionState.Path.CurrentLocation"
	Write-Host "SessionState.Path.CurrentFileSystemLocation: $ExecutionContext.SessionState.Path.CurrentFileSystemLocation"
	$ScriptPath = $ExecutionContext.SessionState.Path.ParseParent('.\', $null)
	Write-Host "ScriptPath from ExecutionContext SessionState.Path.ParseParent: $ScriptPath"
	# $ExecutionContext.SessionState.Path.ParseParent:
	
	$ScriptPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath('..\')
	Write-Host "ScriptPath from ExecutionContext: $ScriptPath"
	# ScriptPath from ExecutionContext: C:\Users\Bruno\LocalDnsApps\unbound\LaunchWatchServiceStart.ps1

	#$ScriptPath = Get-Script-Directory
	#Write-Host "ScriptPath from Get-Script-Directorys: $ScriptPath"
	
	Write-Host "PSVersion Major $PSVersionTable.PSVersion.Major"
	
	## if (-not $ScriptPath) {

    # If using PowerShell ISE
    if ($psISE)
    {
		Write-Host "Running in PowerShell ISE"
        return Split-Path -Parent -Path $psISE.CurrentFile.FullPath
    }
    # If using PowerShell 3.0 or greater
    elseif ($PSVersionTable.PSVersion.Major -gt 3)
    {
		Write-Host "Running in PowerShell 3+"
        return $PSScriptRoot
    }
    # If using PowerShell 2.0 or lower
    else
    {
		Write-Host "Running in PowerShell 2-"
        return Split-Path -Parent $MyInvocation.MyCommand.Path
    }

    # If still not found because an exe was generated using PS2EXE module

	Write-Host "Reading BaseDirectory | PS2EXE module"
	return [System.AppDomain]::CurrentDomain.BaseDirectory.TrimEnd('\')
}
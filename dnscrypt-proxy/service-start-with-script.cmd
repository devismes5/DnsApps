@set @_cmd=1 /*
@echo off
:: brusam, 3-6-2023
:: The EventLog on my Windows 11 system does not log service start events with id 7036
:: I am unwilling to use 'dnscrypt-proxy -syslog' in order to send application logs to the local system logger (Eventlog on Windows)
:: Thus it is impossible to create a task based on System / Service Control Manager / Event Id in the Task Scheduler
setlocal EnableExtensions
title DNSCrypt-Proxy with unbound script

whoami /groups | findstr "S-1-16-12288" >nul && goto :admin
if "%~1"=="RunAsAdmin" goto :error

echo Requesting privileges elevation for managing the dnscrypt-proxy service . . .
cscript /nologo /e:javascript "%~f0" || goto :error
exit /b

:error
echo.
echo Error: Administrator privileges elevation failed,
echo        please manually run this script as administrator.
echo.
goto :end

:admin
pushd "%~dp0"
:: -service ["start" "stop" "restart" "install" "uninstall"]
:: Previously ran 
:: dnscrypt-proxy.exe -service install -config C:\Users\Bruno\LocalDnsApps\dnscrypt-proxy\dnscrypt-proxy.toml
:: in an attempt to avoid events 7046 (unexpected shutdowns)
dnscrypt-proxy.exe -service start


dnscrypt-proxy.exe -service stop
ipconfig /flushdns
dnscrypt-proxy.exe -service start
popd
echo.
echo Thank you for using DNSCrypt-Proxy!

:end
set /p =Press [Enter] to exit . . .
exit /b */

// JScript, restart batch script as administrator
var objShell = WScript.CreateObject('Shell.Application');
var ComSpec = WScript.CreateObject('WScript.Shell').ExpandEnvironmentStrings('%ComSpec%');
objShell.ShellExecute(ComSpec, '/c ""' + WScript.ScriptFullName + '" RunAsAdmin"', '', 'runas', 1);

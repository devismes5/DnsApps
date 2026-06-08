@echo off
:: Gets SERVICE_NAME from sc output like
::   SERVICE_NAME: unbound
::   DISPLAY_NAME: Unbound DNS validator
:: Author: brusam, 31-5-2026
setlocal enabledelayedexpansion
:set_var
set /A SUCCESS=0
set /A NO_SERVICE_FOUND=10

set "SVC_NAME=unbound"
set "LINE_START=SERVICE_NAME:"

:exec
for /F "tokens=2* delims=: " %%a in (
	'sc query "%%SVC_NAME%%" ^| findstr "%%LINE_START%%"'
) do (
    set "LINE_START_STR=%%a"
)
echo LINE_START_STR: [!LINE_START_STR!]

if "!LINE_START_STR!"=="%SVC_NAME%" goto end
:err
exit /b %NO_SERVICE_FOUND%

:end
exit /b %SUCCESS%
endlocal
@echo off
setlocal  enabledelayedexpansion
:: enablecmdextensions
echo.
echo [1] Is delayed expansion enabled? 
echo    %__VSI__%
echo.

set "SVC_NAME=unbound"
echo [2] SVC_NAME = [%SVC_NAME%]

for /F "tokens=2* delims=: " %%a in (
  'sc query "%%SVC_NAME%%" ^| findstr "SERVICE_NAME:"'
) do (
    echo [3] Token %%a = [%%a]
    
    set "LINE_START_STR=%%a"
    echo [4] After SET LINE_START_STR:
    echo      %%a = [%%a]
    echo      LINE_START_STR = [%LINE_START_STR%]
    echo      !LINE_START_STR! = [!LINE_START_STR!]
)

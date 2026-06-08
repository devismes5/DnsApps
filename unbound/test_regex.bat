@echo off
:: Test DOS shell pathname truncation
:: brusam, 31-5-2026
::
set "SCRIPT_DIR=%~dp0"
:: To remove the final backslash, you can use the :n,m substring syntax
set "SCRIPT_DIRPATH=%SCRIPT_DIR:~0,-1%"
:: Alternatevely
for %%i in ("%~dp0.") do SET "SCRIPT_PATH=%%~fi"
echo SCRIPT_PATH %SCRIPT_PATH%

echo TRUNC %SCRIPT_DIR:~0,-1%
echo ---
echo SCRIPT_DIRPATH %SCRIPT_DIRPATH%
echo SCRIPT_DIR %SCRIPT_DIR%

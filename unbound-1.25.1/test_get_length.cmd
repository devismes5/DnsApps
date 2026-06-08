@echo off
:: Test for get_length
:: brusam, 31-5-2026
:: Get the script dirpath and remove its final backslash
for %%i in ("%~dp0.") do SET "SCRIPT_DIRPATH=%%~fi"
echo SCRIPT_DIRPATH %SCRIPT_DIRPATH%
%SCRIPT_DIRPATH%\get_length "hello there" LEN

echo LEN %LEN%

if "%LEN%"=="11" (
	echo %LEN% is correct
	goto eof
)

echo %LEN% is incorrect
goto err

:eof
exit /b 0
:err
exit /b 10
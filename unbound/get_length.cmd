@echo off
:: Evaluates the length of the first argument and returns it in the second argument
echo ARG %*
if "%~1"=="" (
	echo No arg
	goto eof
)

set "str=%~1*"
call :strLen str len
echo Length: %len%
goto eof

:strLen
setlocal enabledelayedexpansion
set "str=!%~1!"
set "len=0"
for %%A in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
    if "!str:~%%A,1!" neq "" (
        set /a "len+=%%A"
        set "str=!str:~%%A!"
    )
)
endlocal & set "%~2=%len%"
goto eof
:eof

@echo off
dir *.log /B | find /v /c ""
for /f "delims=" %%G in ('dir *.log /B ^| find /v /c ""') do set N=%%G
echo N %N%
if not %N% == 0 (
  echo Copying file.log to file-%N%.log
)
@echo off
setlocal enabledelayedexpansion

set "SVC_NAME=unbound"

for /F "tokens=2* delims=: " %%a in (
  'sc query "%%SVC_NAME%%" ^| findstr "SERVICE_NAME:"'
) do (
    set "LINE_START_STR=%%a"
    echo Service: [!LINE_START_STR!]   :: ✅ Use !VAR! here
)

echo.
echo Outside loop, %%SVC_NAME%% is still [unbound]
echo But %%LINE_START_STR%% = [%LINE_START_STR%]  :: ← This will be empty (expected!)

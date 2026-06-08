@echo off
:: ---------------------------------------------------
:: Launcher script for unbound and view-unbound-log.ps1
:: Checks if 'dnscrypt-proxy' service is running, rotates tthe logs and starts the 'unbound' Windows service
:: brusam, 31-5-2026
:: See https://unbound.docs.nlnetlabs.nl/en/latest/getting-started/configuration.html
:: ---------------------------------------------------
:: Usage: restart-unbound.cmd [debug=1] [-tail=1 [-to=3] [-h] >restart-unbound.log 2>&1
::
echo Args '%*'
:: We need to read the %~0 before we start shifting below
::%~nx1 expands %1 to a file name and extension.
:: %~n1 expands %1 to a file name.
set "SNE=%~nx0"
set "SN=%~n0"

:: Define some constants parametrizable on the command line
:: Set default values for the constants that are parametrizable: 0 = No, 1 = Yes
set /A VERBOSE=1
:: How many log files to keep at any given time; the value 0 will be ignored
set /A MAX_LOGFILES=5
:: Define if we need to dump some logging to STDOUT in the command prompt window, once an 'unbound' service is started
set /A TAIL_LOG=1
:: Define if we wait after the unbound service is restarted
set /A TIME_OUT=3
:read_args
:: Your code using %1
::for /f "delims= " %%P in ('%*') do echo Arg=%%P
:: Check for any arguments to parametrize the constants above.
setlocal EnableDelayedExpansion
set "ARG=%~1"
echo Shifting '%ARG%'...
if "x!ARG!" == "x" (
  echo All parameters have been read
  goto define_constants
)
if "!ARG!" == "/debug" (
  echo VERBOSE %~2
  set /A VERBOSE=%~2
  shift && goto cont_shift
)
if "!ARG!" == "/to" (
  echo TIME_OUT %~2
  set /A TIME_OUT=%~2
  shift && goto cont_shift
)
set "TRUNC_TAIL=!ARG:~0,5!"
echo TAIL_LOG '!TRUNC_TAIL!'
if "!TRUNC_TAIL!" == "/tail" (
  echo TAIL_LOG %~2
  set /A TAIL_LOG=%~2
  shift && goto cont_shift
)
set "TRUNC_MAX=!ARG:~0,4!"
echo TRUNC_MAX '!TRUNC_MAX!'
if "!TRUNC_MAX!" == "/max" (
  echo MAX_LOGFILES %~2
  set /A MAX_LOGFILES=%~2
  shift && goto cont_shift
)
:: if one of the paramaters is /? or /h display the usage message and exit
if "%VAL%" == "/?" goto show_usage "%SNE%" "%SN%"
if "%VAL%" == "/h" goto show_usage "%SNE%" "%SN%"
:: Unexpected param
echo ERROR: Invalid argument/option - '%ARG%'.
echo Type "%SN% /?" for usage.
shift
endlocal
:cont_shift
shift
goto read_args

:define_constants
echo Constants set:
if defined VERBOSE echo VERBOSE %VERBOSE%
if defined TIME_OUT echo TIME_OUT %TIME_OUT%
if defined TAIL_LOG echo TAIL_LOG %TAIL_LOG%
if defined MAX_LOGFILES echo MAX_LOGFILES %MAX_LOGFILES%
:: Define more constants
echo Setting more constants
::goto eof
set "PROXY_SERVICE_NAME=dnscrypt-proxy"
set "SERVICE_NAME=unbound"
::
set /A ERR_NO_PROXY_SERVICE=101
set /A ERR_UNBOUND_CHECKCONF=102
:: To remove the final backslash, you can use the :n,m substring syntax, like so:
set "SCRIPT_DIR=%~dp0"
:: To remove the final backslash, you can use the :n,m substring syntax
set "SCRIPT_DIRPATH=%SCRIPT_DIR:~0,-1%"
set "SERVICE_CONF=%SCRIPT_DIRPATH%\service.conf"

set "LOG_FILE_NAME=%SERVICE_NAME%.log"
set "LOG_FILE_GLOB=%SERVICE_NAME%\*.log"
set "LOG_FILE_PATH=%SCRIPT_DIRPATH%\%LOG_FILE_NAME%"
:: The '@@' string will be substituted with a logfile number
:: THere is no directory path as it is a target for the 'ren' command
set "LOG_FILE_NAME_N=%SERVICE_NAME%-@@.log"
set "REG_PATH=HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\%SERVICE_NAME%"
::::::::::::::::::::::::::::::::::::::::::::::
:: Verify if any params are to be considered
::::::::::::::::::::::::::::::::::::::::::::::




::::::::::::::::::::::::::::::::::::::::::::::
:: Done with the variables, start rocessing
::::::::::::::::::::::::::::::::::::::::::::::
echo Ahoy...
:: We can invoke powershell Get-Service but let's stick with sc
:: We can also check if the service is running a few times:
:: if errorlevel 1 (
::    timeout /t 5 /nobreak >nul
::    goto eof
::)
::echo Is dnscrypt-proxy running?
::powershell (Get-Service "dnscrypt-proxy").Status
:check_proxy_service
call:is_service_running "%PROXY_SERVICE_NAME%"
set /A PROXY_SERVICE_IS_RUNNING=%ERRORLEVEL%
echo Is the '%PROXY_SERVICE_NAME%' service running? %PROXY_SERVICE_IS_RUNNING%
if %PROXY_SERVICE_IS_RUNNING% neq 1 (
  echo Exiting as the proxy service '%PROXY_SERVICE_NAME%' is down >&2
  exit /B %ERR_NO_PROXY_SERVICE%
)

:: Check the configuration file
"%SCRIPT_DIRPATH%\unbound-checkconf" %SERVICE_CONF% >nul

if errorlevel 0 (
  echo No errors in %SERVICE_CONF%
) else (
  echo Cannot proceed because of unbound-checkconf errors in %SERVICE_CONF% >&2
  exit /b %ERR_UNBOUND_CHECKCONF%
)

:: Check if the unbound service is running
:check_own_service
:: TODO Alternatively, powershell (Get-Service "unbound").Status
call:is_service_running "%SERVICE_NAME%"
set /A SERVICE_IS_RUNNING=%ERRORLEVEL%
echo Is service '%SERVICE_NAME%' running? %SERVICE_IS_RUNNING%

:flush_zone_and_stop_service
if %SERVICE_IS_RUNNING% == 1 (
	echo Flushing zone cache...
	"%SCRIPT_DIRPATH%\unbound-control" -c "%SERVICE_CONF%" flush_zone . 1>nul
	if not errorlevel 0 (
	  echo Cannot proceed because of zone cache errors >&2
	  exit /b %ERRORLEVEL%
	)

	:: Stop the Windows service
	echo Stopping %SERVICE_NAME%...
	net stop %SERVICE_NAME% 1>nul
	:: Wait 3 secs
	:: TODO Why 3 and why wait? Parametrize.
	echo Stopped, waiting [%ERRORLEVEL%]
	timeout /t 3 /nobreak >nul
)

:: Rotating logs
echo Rotating Unbound log...
dir %LOG_FILE_GLOB% /B
for /f "delims=" %%G in ('dir *.log /B ^| find /v /c ""') do call:rotate_logfiles %%G

:: Launch the Windows service 'unbound'
:start_service
echo Starting service '%SERVICE_NAME%'...
:: Display the ImagePath from the registry, so we are reminded of what is actually running;
:: ImagePath has multiple values due to its type REG_EXPAND_SZ
:: If you don't like the command (you had set the switches to -d -vv -c), you can reset it to the default one by running:
:: reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\unbound" /t REG_EXPAND_SZ /v ImagePath /d "\"C:\DnsApps\unbound\unbound.exe\" -c \"C:\DnsApps\unbound\service.conf\" -w service" /f
for /F "tokens=3*" %%A in ('reg query "%REG_PATH%" /v "ImagePath"') DO (echo Running command: %%A %%B)
:: Start the Windows service instead of using unbound-control
echo Started %LOG_FILE_PATH%
> "%LOG_FILE_PATH%" echo. && net start %SERVICE_NAME% 
::1>nul
echo Started %SERVICE_NAME% [%ERRORLEVEL%] [%TAIL_LOG%]

if %TAIL_LOG% neq 0 (
  echo Waiting for service '%SERVICE_NAME%' to start...
  :: Wait 5 secs for the service to start up and to write something into the log file
  timeout /t 5 /nobreak >nul

  :: Tail the log file displaying humand-readable timestamps
  echo.
  echo Log (local time):
  powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIRPATH%\view-unbound-log.ps1"
)
echo.
echo Done!
:eof
exit /B %ERRORLEVEL%
:::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
:: Callable codeblocks
::
:: Rotating logs
:: Count the log files in the bare dir list
:: Parameter: number of log files unbound.log, unbound-1.log, unbound-2.log,...
:: If there are several files, we are starting at the top of the list, which makes it easy to rename any *-N.log file to *N+1.log
::
:rotate_logfiles
echo In rotate_logfiles [%~1]
if not exist %LOG_FILE_PATH% (
  echo Log file '%LOG_FILE_PATH%' not found; skipping log rotation
  exit /b  0
)
setlocal EnableDelayedExpansion
set /A num_files=%~1
echo Got num_files !num_files!
if !num_files! == 0 (
  echo 'No log files found'
  exit /b 0
)
echo Before call:rotate_numbered_logfiles !num_files!
call:rotate_numbered_logfiles !num_files!
echo After call:rotate_numbered_logfiles !num_files!
::> "%SCRIPT_DIRPATH%\unbound.log" echo.
endlocal
echo Out rotate_logfiles [%~1]
::exit /B 0
goto eof
:: Define a callable code block
:rotate_numbered_logfiles
echo In rotate_numbered_logfiles [%~1]
if "#%~1" == "#" (
  echo No argument passed to rotate_numbered_logfiles
  goto eof
)
setlocal EnableDelayedExpansion
set /A num_files=%~1
:: Reduce by 1 since there is no *-0.log
set /A file_num=num_files-1
call:rotate_numbered_logfile !file_num!
endlocal
echo Out rotate_numbered_logfiles [%~1]
goto eof
:: Define a callable code block
:rotate_numbered_logfile
echo In rotate_numbered_logfile [%~1]
if "#%~1" == "#" (
  echo No argument passed to rotate_numbered_logfile
  goto eof
)
setlocal EnableDelayedExpansion
set /A file_num=%~1
echo Rotate file #!file_num!
set /A next_num=file_num + 1
echo.   next_num #!next_num!
call set "next_numbered_logfile=%%LOG_FILE_NAME_N:@@=!next_num!%%"
if !file_num! equ 0 (
  if %VERBOSE% neq 0 echo Rename first file
  call:rename_numbered_logfilepath "%LOG_FILE_NAME%" "!next_numbered_logfile!"
  if %VERBOSE% neq 0 echo Rotated first file
  goto cont_exit
) else (
  if %VERBOSE% neq 0 echo Rename file not ZERO #!file_num!
)

call set "numbered_logfile=%%LOG_FILE_NAME_N:@@=!file_num!%%"
if %VERBOSE% neq 0 echo logfile#!file_num! !numbered_logfile!

set "numbered_logfile_path=%SCRIPT_DIRPATH%\%numbered_logfile%"
::
:: If an LN-numbered file exists, move it to the LNN file
:: If MAX_LOGFILES is reached delete the last, the one with number MAX_LOGFILES-1
:: e.g. if 5 max, and we have unbound.log, unbound-1.log, ..., unbound-4.log: 4 numbered, 1 unnumbered
:: delete unbound-4.log and rename the other logfiles N -> N+1 as usual.
::
if %VERBOSE% neq 0 echo Before exist File '!numbered_logfile_path!' MAX_LOGFILES [%MAX_LOGFILES%]
if exist "!numbered_logfile_path!" (
  echo File path '!numbered_logfile_path!' exists

  echo Got next_num !next_num! equ %MAX_LOGFILES%

  if !next_num! GEQ %MAX_LOGFILES% (
	echo Deleting '!numbered_logfile_path!' as there are enough [%MAX_LOGFILES%] files already
    del /Q !numbered_logfile_path!
	echo Deleted !numbered_logfile_path! ? !ERRORLEVEL!
    goto :cont
  )

  set "next_numbered_logfile_path=%SCRIPT_DIRPATH%\!next_numbered_logfile!"
  if exist "!next_numbered_logfile_path!" (
	call:delete_next_numbered_logfile_path "!next_numbered_logfile_path!"
  )
  
  call:rename_numbered_logfilepath "!numbered_logfile_path!" "!next_numbered_logfile!"
) else (
  echo Logfile path '!numbered_logfile_path!' does NOT exist; skipping
)

:: Just a label
:cont
echo In cont File '!numbered_logfile!'
:: Check if we need to recurse
set /A prev_num=file_num - 1
echo Got prev_num !prev_num!
if !prev_num! neq 0 (
  call:rotate_numbered_logfile !prev_num!
) else (
  echo Zero reached; backing up 
  :: If 0 reached, move the unnumbered file to the numbered one
  call:backup_current_log_file_to_numbered "!numbered_logfile!"
)
echo Out cont File path '!numbered_logfile!'
endlocal
:cont_exit
echo Out rotate_numbered_logfile [%~1]
goto eof

:: Define a callable code block
:delete_next_numbered_logfile_path
echo In delete_next_numbered_logfile_path [%~1]
setlocal EnableDelayedExpansion
  set "next_numbered_logfile_path=%~1"
  echo Deleting next numbered filepath !next_numbered_logfile_path!
  del "!next_numbered_logfile_path!"
  set /A is_next_numbered_logfile_path_deleted=!ERRORLEVEL!
  echo Deleted !next_numbered_logfile_path! ? !is_next_numbered_logfile_path_deleted!
  if !is_next_numbered_logfile_path_deleted! neq 0 (
    echo Cannot proceed to renaming because of '!next_numbered_logfile_path!' was not deleted
    goto :cont
  )
endlocal
echo Out delete_next_numbered_logfile_path [%~1]
goto eof
:: Define a callable code block
:rename_numbered_logfilepath
echo In rename_numbered_logfilepath [%~1] [%~2]
setlocal EnableDelayedExpansion
  set "numbered_logfile_path=%~1"
  set "next_numbered_logfile=%~2"
  echo Renaming '!numbered_logfile_path!' to '!next_numbered_logfile!'
  ren "!numbered_logfile_path!" "!next_numbered_logfile!"
  set /A is_numbered_logfile_path_renamed=!ERRORLEVEL!
  echo Renamed !numbered_logfile_path! ? !is_numbered_logfile_path_renamed!
  if !is_numbered_logfile_path_renamed! neq 0 (
    echo Cannot proceed because of '!numbered_logfile_path!' was not renamedif
	goto :cont
  )
endlocal
echo Out rename_numbered_logfilepath [%~1] [%~2]
goto eof
:: Define a callable code block
:backup_current_log_file_to_numbered
echo In backup_current_log_file_to_numbered [%~1]
setlocal EnableDelayedExpansion
set "numbered_logfile=%~1"
echo Moving %LOG_FILE_PATH% to !numbered_logfile!
ren "%LOG_FILE_PATH%" "!numbered_logfile!"
if not errorlevel 0 (
  echo Cannot proceed because of errors while moving
)
endlocal
echo Out backup_current_log_file_to_numbered [%~1]
goto eof
:: Define a callable code block
:is_service_running
echo In is_service_running
setlocal EnableDelayedExpansion
set "svc_name=%~1"
::sc query "%svc_name%
for /F "tokens=3,4 delims=: " %%A in ('sc query "%svc_name%" ^| findstr "        STATE"') do (
  echo Service status %%A
  if /I "%%A" == "RUNNING" (
    echo Service is running
	echo Out is_service_running: running
	exit /B 1 :: yes
  )
  echo Out is_service_running: not running
  exit /B 0 :: no
)
endlocal
echo Out is_service_running
exit /B -1 :: no services found for the given name

:show_usage
:: The first argument is the script name with filename extension, the second the script name without extension
echo.
echo.Usage: %~1 [/debug=1] [/tail[log]=1] [/max[log]=5] [/to=3] [/?^|/h] ^>%~2.log 2^>^&1
echo.  where /debug - debug level; default=1, 0 suppresses any debugging statements
echo.        /tail or /taillog - if the service log (that does not feature any readable timestamps) should be tailed with datetimes converted
echo.        /max or /maxlog - how many log files to keep, including %LOG_FILE_NAME%
echo.        /to - if and how many seconds to wait after the service end; default: no
echo.        /? alias /h - display the usage message and ignore all other arguments 
goto eof
:: == END OF SCRIPT ==
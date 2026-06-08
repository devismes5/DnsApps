@echo off
FOR /F "delims=" %%K IN ('REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters") DO (
    
    echo Query the "DisplayName" value from within each subkey "%%K"
)
    ::FOR /F "tokens=2*" %%A IN ('REG QUERY "%%K" /v DisplayName 2^>NUL') DO (
    ::    ECHO   -> %%B
    ::)

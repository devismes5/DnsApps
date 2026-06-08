Get-WinEvent -LogName System | Where-Object {
    $_.Id -eq 7036 -and
    $_.Message -like "*dnscrypt*running*"
} | Select-Object TimeCreated, Message
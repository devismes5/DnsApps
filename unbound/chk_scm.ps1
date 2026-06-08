# See all event IDs that Service Control Manager is actually using
Get-WinEvent -LogName System -MaxEvents 10000 |
    Where-Object {
		$_.ProviderName -eq "Service Control Manager"
		$_.Properties[0].Value -eq "DNSCrypt client proxy"
	} |
    Select-Object Id, Message -Unique |
    Sort-Object Id |
    Format-List
$event = Get-WinEvent -FilterHashtable @{LogName='System'; ID=6037} -MaxEvents 1
[xml]$xml = $event.ToXml()
$xml.Event.EventData.Data  # Extract named data fields [web:11]
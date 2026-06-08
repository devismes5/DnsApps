$xmlQuery = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">
      *[System[Provider[@Name='Service Control Manager']
      and TimeCreated[timediff(@SystemTime) &lt;= 691200000]]]
      and *[EventData[Data='DNSCrypt client proxy']]
    </Select>
  </Query>
</QueryList>
"@

Get-WinEvent -FilterXml $xmlQuery | ForEach-Object {
    $i = 0
    Write-Host "--- Id: $($_.Id) | Time: $($_.TimeCreated) ---"
    $_.Properties | ForEach-Object {
        Write-Host "Properties[$i]: $($_.Value)"
        $i++
    }
    Write-Host ""
}
## DNS Apps

### The reason for the validator-cum-proxy set-up and the attendant coding effort

I am not at all obsessed by privacy but  on my Acer Aspire 5 notebook I have installed both DNSCrypt-proxy v2.1.16 and Unbound v1.25.1, both the latest versions as of May 2026.

To quote a comment by Patrick Mevzek (Sep 13, 2022):

> \[There is an] important difference (with lots of people trying to pretend it doesn't exist) between securing the transport (where DoH/DoT come into play) and securing the content (Where DNSSEC comes into play). When you talk about security
 and "beneficial" you need to list first what you are trying to protect yourself against?
> - Do you want people (ex: ISP) not to snoop on your DNS traffic? Then you might need DoH/DoT.
> - Do you want to have guarantees on data received? You need DNSSEC.
> - And you can do both.

### Why DNSCrypt-proxy

DNSCrypt-proxy is a client that initiates encrypted connections (DNSCrypt, DoH, Anonymized DNS) to upstream resolvers. It provides caching, load balancing, filtering, and supports more protocols (including Anonymized DNS and ODoH)

### Why Unbound

Unbound is a full-featured, local DNS resolver and cache. It can be configured to forward queries to a client like dnscrypt-proxy.

### Installation

As shown in the ArchWiki guide, the standard and recommended setup is:
- *unbound* (on port 53, caching and validating)
- forwards queries to *dnscrypt-proxy* (e.g., on port 5353)

DNSCrypt-proxy handles encryption (DoH, DNSCrypt) and forwards to the upstream resolver.


Below I am using the imperative mode for simplicity :)

---
After forking the code create symbolic links to the folders that had their version numbers in their names.
Replacing them with new versions should be easy this way. I would still need to copy the artefacts I created, I know.

In the DnsApps folder:

```
mklink /D /J unbound unbound-1.25.1
mklink /D /J dnscrypt-proxy dnscrypt-proxy-win64-2.1.16\win64
mklink mkcert.exe mkcert-v1.4.4-windows-amd64.exe
```

<details>
  <summary>Preliminary Steps</summary>

Set ExecutionPolicy to RemoteSigned

```PowerShell
Set-ExecutionPolicy -scope Process -ExecutionPolicy RemoteSigned
```

WinCS API needs to be installed and set up. With the optional update from October 28 2023? (KB5067036), Microsoft introduced a CLI tool for the WinCS API. 
Install as explained at https://support.microsoft.com/en-us/topic/windows-configuration-system-wincs-apis-for-secure-boot-d3e64aa0-6095-4f8a-b8e4-fbfda254a8fe

...and apply the module F33E0C8E002:

```PowerShell
WinCsFlags.exe /apply --key "F33E0C8E002"
WinCsFlags.exe /query --key F33E0C8E002
```

Check whether the Windows UEFI CA 2023 certificate is already present on your system:

```PowerShell
([System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match ‘Windows UEFI CA 2023’)
```

Install the UEFI CA 2023 PowerShell module:

```PowerShell
Install-Module UEFIv2 -Force
```
You can list the certificates:

```PowerShell
Get-UEFISecureBootCerts db | select SignatureSubject
```

Enable SecureBoot:

```PowerShell
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecureBoot" -Name "AvailableUpdates" -Value 0x40
```

Now, run the Scheduled Task `Secure-Boot-Update`.

One can also manually trigger the Secure Boot servicing task by following below steps: 

```
Start-ScheduledTask -TaskName "\Microsoft\Windows\PI\Secure-Boot-Update"
```

2x reboot

```
[System.Text.Encoding]::ASCII.GetString((Get-SecureBootUEFI db).bytes) -match 'Windows UEFI CA 2023'
True
```

In case any w32tm errors are reported, restart w32tm:
```
net stop w32time
w32tm.exe /unregister 
w32tm.exe /register 
net start w32time
```

In Registry Editor, navigate to HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole and look for or create these DWORD values:

- RemoteActivationTimeout (30000 ms by by default)
- LocalActivationTimeout (30000 ms by default)

Increase these values (e.g., to 60000 ms)

```
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole" /v RemoteActivationTimeout /t REG_DWORD /d 60000
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole" /v LocalActivationTimeout /t REG_DWORD /d 60000
reg query HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Ole
```
</details>

Having created the symlinks go through the usual steps recommended in the project docs:

<details>
  <summary>DNSCrypt-proxy</summary>

Check in tasklist if the process is running

```
tasklist /fo table /svc  | findstr proxy
dnscrypt-proxy.exe           20548 dnscrypt-proxy
```

Set dnscrypt-proxy as an AUTO_START  (DELAYED) service.

View the registry settings:
```
reg query HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dnscrypt-proxy
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\dnscrypt-proxy
    Type    REG_DWORD    0x10
    Start    REG_DWORD    0x2
    ErrorControl    REG_DWORD    0x0
    ImagePath    REG_EXPAND_SZ    C:\Users\Bruno\LocalDnsApps\dnscrypt-proxy\dnscrypt-proxy.exe -config dnscrypt-proxy.toml
    DisplayName    REG_SZ    DNSCrypt client proxy
    ObjectName    REG_SZ    LocalSystem
    Description    REG_SZ    Encrypted/authenticated DNS proxy
    DelayedAutostart    REG_DWORD    0x1
```

Check port 53:

```
powershell -ExecutionPolicy Bypass Get-NetTCPConnection -LocalPort 53

LocalAddress                        LocalPort RemoteAddress                       RemotePort State       AppliedSetting
------------                        --------- -------------                       ---------- -----       --------------
::1                                 53        ::                                  0          Listen
127.0.0.1                           53        0.0.0.0                             0          Listen
```

Modifying the ImagePath command in the Windows registry - e.g. if the folder path was changed - does not seem to work, as it does for the unbound service:
```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\DNSCrypt-proxy" /t REG_EXPAND_SZ /v ImagePath /d "C:\AppDevProjects\DnsApps\dnscrypt-proxy\dnscrypt-proxy.exe -config dnscrypt-proxy.toml -w service" /f
```

The scripts needs to be executed:

```
service-uninstall && service-install
```

Also add connection anonymization.

My contribution was installing the certificates and referencing them in the conf file.

</details>

<details>
  <summary>Unbound</summary>

Unbound should run on port 53 once DNSCrypt-proxy is running on port 5353.

Set Start mode to Manual (DEMAND_START).

My contribution: restart-unbound.cmd

The DNSCrypt-proxy service needs to be running for Unbound to forward to it. DNSCrypt client proxy does not write to the EventLog making it impossible to latch unbound onto a service start-up event.

Unbound needs certificates to forward traffic, so install MkCert v1.4.4, create `localhost+2-key.pem` and `localhost+2.pem` running `mkcert -client` (i.e. "Generate a certificate for client authentication.")
To see all MkCert options: `mkcert -help`

To check if the services has been installed:

```
>sc queryex type= service state= all | findstr /i "unbound"
SERVICE_NAME: unbound
DISPLAY_NAME: Unbound DNS validator
```

Start the service: `unbound-control -c service.conf start`  or simply `net start unbound`. It is not clear to me why the former be better than latter.

Check the registry settings for *unbound*, in particular _ImagePath_ that holds the command expression being executed:

```
reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\unbound"

HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\unbound
    Type    REG_DWORD    0x10
    Start    REG_DWORD    0x2
    ErrorControl    REG_DWORD    0x1
    ImagePath    REG_EXPAND_SZ    "C:\AppDevProjects\DnsApps\unbound\unbound.exe" -c "C:\AppDevProjects\DnsApps\unbound\service.conf" -w service
    DisplayName    REG_SZ    Unbound DNS validator
    ObjectName    REG_SZ    LocalSystem
```

If more debugging is needed, modify the ImagePath, enabling the debug mode by adding the switches `-d -v` or `-d -vv` after `unbound.exe`:

```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\unbound" /t REG_EXPAND_SZ /v ImagePath /d "\"C:\AppDevProjects\DnsApps\unbound\unbound.exe\" -d -v -c \"C:\AppDevProjects\DnsApps\unbound\service.conf\" -w service" /f
```

and eventually switch back to the original command

```
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\unbound" /t REG_EXPAND_SZ /v ImagePath /d "\"C:\AppDevProjects\DnsApps\unbound\unbound.exe\" -c \"C:\AppDevProjects\DnsApps\unbound\service.conf\" -w service" /f
```

Check in the tasklist if the process is running:

```
tasklist /fo table /svc  | findstr unbound
dnscrypt-proxy.exe           20548 dnscrypt-proxy
```

In order to find the number of processors, use

```
wmic cpu get NumberOfCores,NumberOfLogicalProcessors
10  12
```

as systeminfo reports a strange message

```
systeminfo | findstr /C:"Processor(s)"
Processor(s):                  1 Processor(s) Installed.
```

</details>


### Test chain with tests

https://one.one.one.one/help/ (CloudFlare 1.1.1.1)

https://dnsleaktest.com/

https://dnscheck.tools/

### Caveat

[DNS Privacy Test](https://publicdns.info/dns-privacy-check.html) is amazingly complex and complete but I still need to get my head over the reason that enabling DNSSEC in DNSCrypt-proxy does not seem to produce the expected security. My metrics are decidedly modest:

| **Test** | Weight | Result | Score | Comment |
|--------|--------|--------|--------|--------|
| **DNS Leak Detection** | Weight: 20% | Passed | Score: 100/100 | All 3 test rounds resolved through a single DNS server (146.70.82.3). No DNS leak detected. |
| **Encrypted DNS (DoH/DoT)** | Weight: 20% | Warning | Score: 30/100 | DoH endpoints are reachable, but your DNS resolver is not a known encrypted DNS provider. Your queries are likely unencrypted. Enable DoH in your browser or switch to a privacy DNS. |
| **DNSSEC Validation** | Weight: 10% | Warning | Score: 40/100 | Both test domains were unreachable. This may indicate network restrictions rather than DNSSEC validation. Results are inconclusive. |
| **IPv6 Exposure (WebRTC)** | Weight: 10% | Passed | Score: 100/100 | No IPv6 addresses detected via WebRTC. Your device does not appear to expose IPv6 connectivity that could leak DNS queries. |
| **ECH/ESNI Support** | Weight: 15% | Passed | Score: 100/100 | Encrypted Client Hello (ECH) is active. The SNI field in your TLS handshakes is encrypted, preventing network observers from seeing which domains you connect to. |
| **DNS Server Identification** | Weight: 10% | Warning | Score: 30/100 | DNS resolver identified: M247 Ltd (AS9009), Germany. This appears to be an ISP DNS server, which typically logs queries. |

**Your DNS Privacy Grade: C — 64 / 100**
[DNS Privacy Test results as of June 7, 2026](./dns-privacy-test.md)

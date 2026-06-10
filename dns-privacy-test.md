Here's all the extracted text:
PublicDNS.info test with the current dnscrypt-setup
---

**PublicDNS.info**
Live-tested public DNS. Retested every 72 hours.

# DNS Privacy & Security Check

Test your own DNS or audit any public DNS server for DNSSEC, encryption, NXDOMAIN hijacking, and more. Get an instant privacy grade.

Last updated: June 2026 · Vendor-neutral

DNS leak detection uses real authoritative DNS callbacks via dnsprobe.online to identify your actual resolver. Other tests (encrypted DNS, ECH) use browser-side heuristics. For a definitive audit of a specific server, use "Check a Specific DNS Server".

Viewing a shared result (D, 45/100). Run your own test

---

**DNS Leak Detection** — Weight: 20%
Passed
Score: 100/100
All 3 test rounds resolved through a single DNS server (146.70.82.3). No DNS leak detected.

**Encrypted DNS (DoH/DoT)** — Weight: 20%
Warning
Score: 30/100
DoH endpoints are reachable, but your DNS resolver is not a known encrypted DNS provider. Your queries are likely unencrypted. Enable DoH in your browser or switch to a privacy DNS.
How to fix

**DNSSEC Validation** — Weight: 25%
Warning
Score: 40/100
Both test domains were unreachable. This may indicate network restrictions rather than DNSSEC validation. Results are inconclusive.
How to fix

**IPv6 Exposure (WebRTC)** — Weight: 10%
Passed
Score: 100/100
No IPv6 addresses detected via WebRTC. Your device does not appear to expose IPv6 connectivity that could leak DNS queries.

**ECH/ESNI Support** — Weight: 15%
Passed
Score: 100/100
Encrypted Client Hello (ECH) is active. The SNI field in your TLS handshakes is encrypted, preventing network observers from seeing which domains you connect to.

**DNS Server Identification** — Weight: 10%
Warning
Score: 30/100
DNS resolver identified: M247 Ltd (AS9009), Germany. This appears to be an ISP DNS server, which typically logs queries.
How to fix

---

**Your DNS Privacy Grade: C — 64 / 100**

**Detected DNS Servers**
146.70.82.3 — M247 Ltd — AS9009 — Germany — ISP DNS

**Test History**
C — 64/100 · 1 resolver(s) — 2026-06-07 15:34

---

## What is a DNS privacy check?

The Domain Name System was designed in the 1980s with zero privacy protections. Every time you type a website address into your browser, a DNS query translates that domain name into an IP address. These queries travel across the network in plaintext. Your ISP, your network administrator, anyone on the same Wi-Fi — they can all see exactly which websites you are visiting.

HTTPS encrypts the content of web pages, but the DNS queries that precede every connection are still visible. This metadata reveals your browsing patterns. ISPs in many countries are legally permitted (or even required) to log DNS queries and build profiles of their customers' online activity. Governments use DNS monitoring for censorship. Advertisers use it for targeting. The page content is encrypted, but the envelope is wide open.

## Why DNS leak testing matters

Your DNS traffic is a complete log of every domain you visit, every service you use. Even with HTTPS everywhere, DNS gives it all away. ISPs sell aggregated browsing data to advertisers. Network administrators monitor employee activity. Public Wi-Fi operators intercept queries to inject ads. Attackers perform DNS hijacking to redirect you to phishing sites that steal credentials.

It goes beyond personal browsing. DNS queries reveal which cloud services an organisation uses, which security vendors they rely on, which partners they communicate with. For journalists and activists in authoritarian regimes, DNS monitoring can have life-threatening consequences.

## How this tool works and its limitations

This tool has two modes. "Check My DNS" runs browser-side heuristic tests using WebRTC and fetch APIs. "Check a Specific DNS Server" runs server-side tests using actual DNS queries via `dig`, which produces definitive results for DNSSEC validation, NXDOMAIN hijacking, DNS-over-TLS support, and response time.

**DNS Leak Detection** uses the industry-standard authoritative DNS callback technique. Your browser resolves a unique subdomain (via dnsprobe.online), and our authoritative DNS server logs which resolver IP actually queried it. This reveals the real DNS server handling your queries — not just your IP, but the resolver your OS is sending queries to. If you are using a VPN, the resolver should belong to the VPN provider. If it belongs to your ISP instead, your DNS is leaking. This is the same technique used by dnsleaktest.com and similar tools.

**Encrypted DNS Reachability** checks whether known DoH endpoints (Cloudflare, Google) are reachable from your browser. This indicates whether encrypted DNS is available to you, but it cannot definitively confirm whether your current DNS queries are actually encrypted. To verify encryption, use your OS or browser DNS settings to explicitly enable DoH or DoT.

**DNSSEC Validation** checks whether your resolver verifies cryptographic signatures on DNS records. This prevents cache poisoning attacks where an attacker forges DNS responses to redirect you to malicious servers. The test uses specially crafted domains with known-bad DNSSEC signatures. If your resolver accepts these invalid signatures, it is not performing proper validation.

The **IPv6 Leak Detection** test discovers whether your device exposes IPv6 addresses that could bypass your VPN tunnel. Many VPN configurations only handle IPv4 traffic, leaving IPv6 DNS queries to travel directly to your ISP resolver. This dual-stack leak is a common and often overlooked privacy gap.

**ECH/ESNI Support** testing checks whether your browser supports Encrypted Client Hello, which hides the domain name during TLS handshakes. Without ECH, even with encrypted DNS and HTTPS, network observers can see which specific domain you are connecting to by inspecting the plaintext Server Name Indication (SNI) field.

Finally, **DNS Server Identification** attempts to determine which DNS resolver you are actually using. By examining CDN edge routing and timing patterns, the tool can identify whether you are using a known privacy-focused provider, your ISP default, or an unknown resolver.

## Understanding Your Score

Your overall privacy grade is a weighted average of six tests. DNSSEC validation carries the highest weight (25%) because it is the most reliable browser-side test and protects against DNS spoofing. IP leak detection and encrypted DNS reachability each carry 20%. ECH support (15%), IPv6 exposure (10%), and DNS server identification (10%) complete the score. For the most accurate results, use the "Check a Specific DNS Server" mode, which runs server-side tests with definitive answers.

A grade of A+ (95–100) means your DNS configuration has excellent privacy protections. An A (85–94) indicates strong privacy with minor areas for improvement. A B (70–84) is good but has notable gaps. A C (55–69) suggests significant privacy weaknesses. A D (40–54) means most of your DNS traffic is exposed. An F (below 40) indicates critical privacy failures that should be addressed immediately.

To improve your score, start with the highest-weighted failing tests. Enable encrypted DNS in your browser or operating system, ensure your VPN handles DNS properly, and consider switching to a privacy-focused DNS provider. For detailed setup instructions, see our guides on DoH vs DoT, changing DNS on Linux, and setting up Unbound as a recursive resolver.

---

## Frequently Asked Questions

**What is a DNS privacy check?**
A DNS privacy check tests whether your DNS queries are being sent securely and privately. It verifies that your DNS traffic is encrypted, your resolver validates DNSSEC signatures, and your real IP address is not leaking through DNS requests. This helps you understand how exposed your browsing activity is to surveillance, ISP tracking, or man-in-the-middle attacks.

**What is a DNS leak and why is it dangerous?**
A DNS leak occurs when your DNS queries bypass your VPN or encrypted tunnel and are sent to your ISP default resolver instead. This exposes every website you visit to your ISP, even when you think your traffic is private. DNS leaks can also reveal your real location and identity to websites, defeating the purpose of using a VPN.

**What is encrypted DNS (DoH and DoT)?**
Encrypted DNS protocols wrap your DNS queries in TLS encryption. DNS-over-HTTPS (DoH) sends queries over port 443 alongside regular web traffic, making it hard to block or detect. DNS-over-TLS (DoT) uses a dedicated port 853 with TLS encryption. Both prevent your ISP and network operators from seeing which domains you resolve.

**What is DNSSEC and why does it matter?**
DNSSEC (Domain Name System Security Extensions) adds cryptographic signatures to DNS records. When your resolver validates DNSSEC, it can detect if a DNS response has been tampered with during transit. Without DNSSEC validation, attackers can redirect you to malicious sites through DNS cache poisoning attacks.

**How does IPv6 affect DNS privacy?**
IPv6 addresses can leak through WebRTC or misconfigured VPN tunnels. Even if your IPv4 traffic is properly routed through a VPN, IPv6 DNS queries might bypass the tunnel and go directly to your ISP resolver. This dual-stack leak reveals your real IPv6 address and DNS activity to anyone monitoring your network.

**What is ECH/ESNI and how does it protect privacy?**
Encrypted Client Hello (ECH), the successor to Encrypted Server Name Indication (ESNI), encrypts the SNI field in TLS handshakes. Without ECH, even with encrypted DNS and HTTPS, the domain name you are connecting to is visible in plaintext during the TLS handshake. ECH hides this information from network observers.

**What DNS privacy grade should I aim for?**
Aim for at least a B grade (70+). An A or A+ grade means your DNS setup has strong privacy protections including encrypted DNS, DNSSEC validation, and no detectable leaks. A C or lower indicates significant privacy gaps that should be addressed by switching to a privacy-focused DNS resolver with DoH or DoT support.

**How can I improve my DNS privacy score?**
Switch to a privacy-focused DNS resolver like Cloudflare (1.1.1.1) or Quad9 (9.9.9.9) with encrypted DNS enabled. Use DoH or DoT in your browser or operating system settings. Ensure your VPN properly handles DNS to prevent leaks. Enable DNSSEC validation on your resolver. Use a browser that supports ECH, such as recent Firefox versions.

---

## Related Tools

**DNS Gaming Benchmark** — Test DNS latency from your location and find the fastest resolver for gaming. Compare 20+ public DNS servers with real-time ping measurements.

**DNS Dig Lookup** — Query DNS records for any domain directly from your browser. Supports A, AAAA, MX, NS, TXT, CNAME, SOA and more record types.

**DNS Servers by Country** — Browse public DNS servers available in your country, with live reliability and latency data.
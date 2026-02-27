---
name: connections
description: Show all network connections on this machine with process info, IP ownership (whois), and reverse DNS as JSON.
metadata: { "openclaw": { "emoji": "🌐", "os": ["darwin", "linux"], "requires": { "bins": ["jq", "whois", "dig"] } } }
---

# Network Connections

When the user invokes `/connections`, run the `netjson.sh` script located at `{baseDir}/netjson.sh` using `sudo` for full process visibility:

```
sudo {baseDir}/netjson.sh
```

The script outputs JSON with every network socket (ESTABLISHED, LISTEN, CLOSE_WAIT, TIME_WAIT, CLOSED, UDP, ICMP) including:
- `pid` — process ID
- `process` — process name
- `proto` — protocol (TCP, UDP, ICMP, ICMPV6)
- `direction` — `outbound` (has remote IP) or `listen`
- `state` — TCP state (ESTABLISHED, LISTEN, CLOSE_WAIT, etc.) or `-` for stateless
- `local_addr` / `local_port`
- `remote_ip` / `remote_port`
- `rdns` — reverse DNS of the remote IP
- `owner` — registered organization from whois

After running the script, present the results to the user in two clear tables:

1. **Outbound connections** (direction = outbound): show PID, process, remote IP, remote port, state, rDNS, and owner.
2. **Listening services** (direction = listen, state = LISTEN): show PID, process, local port, and proto. Deduplicate entries that differ only by IPv4/IPv6.

Omit rows where direction is `listen` and state is `-` (UDP/ICMP listeners) unless the user asks for them.

If the user provides arguments after `/connections`:
- `--json` or `json`: print the raw JSON only, no tables.
- `--outbound` or `out`: show only outbound connections.
- `--listen` or `listen`: show only listening services.
- `--all`: include UDP/ICMP listeners in the output.

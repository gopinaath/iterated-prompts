# SSH over CGNAT Setup

## Quick Setup

1. Add your CGNAT IP to SSH config:
   ```bash
   sudo nano /etc/ssh/sshd_config.d/local-network-only.conf
   ```

   Add the line:
   ```
   ListenAddress <YOUR_CGNAT_IP>
   ```

2. Reload and restart (both required due to socket activation):
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart ssh.socket
   ```

3. Verify:
   ```bash
   ss -tlnp | grep ':22'
   ```
   Should show both IPs listening on port 22.

## Gotcha: Socket Activation

Modern Ubuntu uses systemd socket activation for SSH. The socket config is auto-generated from `sshd_config` by `sshd-socket-generator`.

**If you only restart sshd, nothing changes.** The socket override lives in `/run/systemd/generator/ssh.socket.d/addresses.conf` and is regenerated on `daemon-reload`.

Wrong:
```bash
sudo systemctl restart sshd  # Won't pick up new ListenAddress
```

Right:
```bash
sudo systemctl daemon-reload    # Regenerates socket config
sudo systemctl restart ssh.socket  # Applies it
```

## Find Your CGNAT IP

```bash
ip addr | grep 'inet 100\.'  # Tailscale/CGNAT range
```

## Test

```bash
ssh youruser@<CGNAT_IP>
```

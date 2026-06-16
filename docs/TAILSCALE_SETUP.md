# Tailscale Integration with ServicePi

Tailscale provides a secure, zero-config VPN that allows you to access your Raspberry Pi and all ServicePi services from anywhere — without opening firewall ports or configuring port forwarding.

ServicePi supports both access modes:

| Traffic source | Protocol | Port | Notes |
|---|---|---|---|
| Local network (LAN) | HTTP | 80, 9000, 8123, … | Unchanged from default |
| Tailscale network | HTTPS | 443 (dashboard/API) | Activated by `setup-tailscale-certs.sh` |
| Tailscale network | HTTP | 80, 9000, 8123, … | WireGuard-encrypted tunnel; no extra TLS needed |

> **Note:** All Tailscale traffic is already end-to-end encrypted by WireGuard. HTTP over Tailscale is private. The optional HTTPS on port 443 adds an additional TLS layer for the main web dashboard and provides a browser-friendly `https://` URL.

---

## Prerequisites

1. A [Tailscale account](https://login.tailscale.com/start) (free tier is sufficient).
2. Tailscale installed on the host Raspberry Pi (`tailscale` CLI available).
3. **HTTPS Certificates** enabled in your tailnet:
   - Navigate to **Admin Console → DNS → HTTPS Certificates** and enable it.

---

## Quick Start

### 1. Install and authenticate Tailscale on the host

```bash
sudo tailscale up
```

Follow the URL printed in the terminal and complete sign-in in the Tailscale admin console.

Verify host Tailscale is authenticated:

```bash
tailscale status
```

You should see this device listed with a `100.x.x.x` Tailscale IP and a MagicDNS name ending in `.ts.net`.

### 2. Access Services over Tailscale (HTTP)

All services are immediately accessible via HTTP over the encrypted Tailscale WireGuard tunnel using the Tailscale IP or MagicDNS hostname:

| Service | URL |
|---|---|
| Web Dashboard | `http://servicepi.tailnet-name.ts.net/` |
| Portainer | `http://servicepi.tailnet-name.ts.net:9000/` |
| Home Assistant | `http://servicepi.tailnet-name.ts.net:8123/` |
| IoT API | `http://servicepi.tailnet-name.ts.net:8080/` |
| Pi-hole Admin | `http://servicepi.tailnet-name.ts.net:8053/` |
| N8N | `http://servicepi.tailnet-name.ts.net:5678/` |
| WordPress | `http://servicepi.tailnet-name.ts.net:8081/` |
| OpenWebUI | `http://servicepi.tailnet-name.ts.net:3000/` |
| SearXNG | `http://servicepi.tailnet-name.ts.net:8888/` |

Replace `tailnet-name` with your actual Tailscale tailnet name (shown in the Tailscale admin console).

### 3. Enable HTTPS on Port 443 (Optional)

For an `https://` entry-point to the web dashboard, run the certificate setup script:

```bash
sudo bash /opt/servicepi/scripts/setup-tailscale-certs.sh
```

After a successful run:
- Web dashboard: `https://servicepi.tailnet-name.ts.net/`
- IoT API: `https://servicepi.tailnet-name.ts.net/api/`

The script:
1. Requests a TLS certificate from Tailscale's certificate authority.
2. Saves the certificate and key to `configs/nginx/certs/`.
3. Activates the HTTPS nginx configuration (`https.conf`).
4. Reloads nginx.

> **Certificate renewal:** Tailscale certificates are valid for 90 days. Re-run the script before expiry to renew.

### Automating certificate renewal

#### Cron job (run as root)

```bash
sudo crontab -e
# Add this line to renew monthly (well within the 90-day window):
0 3 1 * * /opt/servicepi/scripts/setup-tailscale-certs.sh >> /var/log/servicepi-tailscale-cert.log 2>&1
```

#### systemd timer

```ini
# /etc/systemd/system/servicepi-tailscale-cert.service
[Unit]
Description=Renew ServicePi Tailscale TLS certificate
After=docker.service

[Service]
Type=oneshot
ExecStart=/opt/servicepi/scripts/setup-tailscale-certs.sh
StandardOutput=journal
StandardError=journal
```

```ini
# /etc/systemd/system/servicepi-tailscale-cert.timer
[Unit]
Description=Monthly renewal of ServicePi Tailscale TLS certificate

[Timer]
OnCalendar=monthly
Persistent=true

[Install]
WantedBy=timers.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now servicepi-tailscale-cert.timer
```

---

## Host setup notes

- ServicePi does **not** run Tailscale in Docker.
- You can skip Tailscale entirely and continue using ServicePi on your local network.
- Install Tailscale on the host: https://tailscale.com/download
- If you want tailnet access/HTTPS later, install Tailscale on the host and run:

```bash
sudo tailscale up
sudo bash /opt/servicepi/scripts/setup-tailscale-certs.sh
```

## Troubleshooting

### Check Tailscale status

```bash
tailscale status
```

### nginx HTTPS not working

1. Verify certificates exist:
   ```bash
   ls -la /opt/servicepi/configs/nginx/certs/
   ```
2. Verify HTTPS config is active:
   ```bash
   ls /opt/servicepi/configs/nginx/proxy/https.conf
   ```
3. Check nginx config validity:
   ```bash
   docker exec servicepi-proxy nginx -t
   ```
4. Check nginx logs:
   ```bash
   docker logs servicepi-proxy
   ```

### Re-run certificate setup

```bash
sudo bash /opt/servicepi/scripts/setup-tailscale-certs.sh
```

### Disable HTTPS

```bash
rm /opt/servicepi/configs/nginx/proxy/https.conf
docker exec servicepi-proxy nginx -s reload
```

---

## Security Notes

- All Tailscale traffic is end-to-end encrypted by WireGuard regardless of HTTP/HTTPS.
- Services are accessible from the public internet only if a device has a routable public IP and no router-level firewall. Tailscale authentication still controls which Tailscale-network devices can connect via the `100.x.x.x` addresses.
- UFW opens port 443 on all interfaces (same as all other service ports). Port 443 only responds with HTTPS after running `setup-tailscale-certs.sh`; before that, connections are refused. This is acceptable for a home LAN where inbound internet traffic is blocked at the router.
- For stricter access control, you can restrict port 443 to the Tailscale subnet only by replacing the UFW rule with: `ufw allow from 100.64.0.0/10 to any port 443`
- Private key (`tailscale.key`) is stored in `configs/nginx/certs/` with permissions `600`. Do not commit it.

## Related Documentation

- [README.md](../README.md) - ServicePi overview
- [INSTALL.md](../INSTALL.md) - Installation guide
- [SECURITY.md](../SECURITY.md) - Security considerations
- [Tailscale documentation](https://tailscale.com/kb/)

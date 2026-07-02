# Tailscale Integration with ServicePi

Tailscale provides a secure, zero-config VPN that allows you to access your Raspberry Pi and all ServicePi services from anywhere — without opening firewall ports or configuring port forwarding.

ServicePi supports both access modes:

| Traffic source | Protocol | Port | Notes |
|---|---|---|---|
| Local network (LAN) | HTTP | 80, 9000, … | Unchanged from default |
| Tailscale network | HTTP | 80, 9000, … | WireGuard-encrypted tunnel; works immediately |
| Tailscale network | HTTPS | 443, 9000, 8080, … | Activated by `setup-tailscale-certs.sh` |

> **Note:** All Tailscale traffic is already end-to-end encrypted by WireGuard. HTTP over Tailscale is private. The optional HTTPS (activated by `setup-tailscale-certs.sh`) adds browser-trusted TLS certificates so that all service links show a green padlock and mixed-content warnings are avoided.

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
| IoT API | `http://servicepi.tailnet-name.ts.net:8080/` |
| Pi-hole Admin | `http://servicepi.tailnet-name.ts.net:8053/` |
| N8N | `http://servicepi.tailnet-name.ts.net:5678/` |
| WordPress | `http://servicepi.tailnet-name.ts.net:8081/` |
| OpenWebUI | `http://servicepi.tailnet-name.ts.net:3000/` |
| SearXNG | `http://servicepi.tailnet-name.ts.net:8888/` |

Replace `tailnet-name` with your actual Tailscale tailnet name (shown in the Tailscale admin console).

### 3. Enable HTTPS for All Services (Optional)

For browser-trusted `https://` access to **all** services, run the certificate setup script:

```bash
sudo bash /opt/servicepi/scripts/setup-tailscale-certs.sh
```

After a successful run, every service is accessible over HTTPS using the Tailscale certificate:

| Service | HTTPS URL |
|---|---|
| Web Dashboard | `https://servicepi.tailnet-name.ts.net/` |
| IoT API | `https://servicepi.tailnet-name.ts.net/api/` |
| Portainer | `https://servicepi.tailnet-name.ts.net:9000/` |
| IoT API (direct) | `https://servicepi.tailnet-name.ts.net:8080/` |
| Pi-hole Admin | `https://servicepi.tailnet-name.ts.net:8053/` |
| N8N | `https://servicepi.tailnet-name.ts.net:5678/` |
| WordPress | `https://servicepi.tailnet-name.ts.net:8081/` |
| OpenWebUI | `https://servicepi.tailnet-name.ts.net:3000/` |
| SearXNG | `https://servicepi.tailnet-name.ts.net:8888/` |

The script:
1. Requests a TLS certificate from Tailscale's certificate authority.
2. Saves the certificate and key to `configs/nginx/certs/`.
3. Activates the HTTPS nginx configuration (`00-https.conf`) which adds SSL listeners on all service ports.
4. Reloads nginx.

The web dashboard automatically detects when it is served over HTTPS and updates all service links to use `https://`, so you will never be redirected back to HTTP when clicking through from the dashboard.

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
   ls /opt/servicepi/configs/nginx/proxy/00-https.conf
   ```
3. Check nginx config validity:
   ```bash
   docker exec servicepi-proxy nginx -t
   ```
4. Check nginx logs:
   ```bash
   docker logs servicepi-proxy
   ```

### Service HTTPS not working on a specific port

Each service port (9000, 8080, etc.) has its own HTTPS server block in `00-https.conf`. If one service is not responding over HTTPS, check:

1. The port is open in UFW: `sudo ufw status`
2. nginx is listening on that port: `docker exec servicepi-proxy nginx -t`
3. The relevant service container is running: `docker ps`

### Re-run certificate setup

```bash
sudo bash /opt/servicepi/scripts/setup-tailscale-certs.sh
```

### Disable HTTPS

```bash
rm /opt/servicepi/configs/nginx/proxy/00-https.conf
docker exec servicepi-proxy nginx -s reload
```

---

## Security Notes

- All Tailscale traffic is end-to-end encrypted by WireGuard regardless of HTTP/HTTPS.
- Services are accessible from the public internet only if a device has a routable public IP and no router-level firewall. Tailscale authentication still controls which Tailscale-network devices can connect via the `100.x.x.x` addresses.
- UFW opens all service ports on all interfaces. After running `setup-tailscale-certs.sh`, those ports respond over HTTPS; before that, they respond over HTTP.
- For stricter access control, you can restrict HTTPS ports to the Tailscale subnet only: `ufw allow from 100.64.0.0/10 to any port 443`
- Private key (`tailscale.key`) is stored in `configs/nginx/certs/` with permissions `600`. Do not commit it.

## Related Documentation

- [README.md](../README.md) - ServicePi overview
- [INSTALL.md](../INSTALL.md) - Installation guide
- [SECURITY.md](../SECURITY.md) - Security considerations
- [Tailscale documentation](https://tailscale.com/kb/)

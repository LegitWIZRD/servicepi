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
2. An [Auth Key](https://login.tailscale.com/admin/settings/keys) from the Tailscale admin console.
3. **HTTPS Certificates** enabled in your tailnet:
   - Navigate to **Admin Console → DNS → HTTPS Certificates** and enable it.

---

## Quick Start

### 1. Configure Environment Variables

Add the following to your `.env` file (copy from `.env.example`):

```dotenv
# Tailscale Configuration
TAILSCALE_AUTH_KEY=tskey-auth-xxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TAILSCALE_HOSTNAME=servicepi
```

> Generate an auth key at: https://login.tailscale.com/admin/settings/keys  
> Use a **reusable** key for long-term operation, or an **ephemeral** key for temporary access.

### 2. Start the Tailscale Container

```bash
cd /opt/servicepi
docker compose up -d tailscale
```

Verify the container is running and authenticated:

```bash
docker exec servicepi-tailscale tailscale status
```

You should see your device listed as `servicepi` (or your configured hostname) with a `100.x.x.x` Tailscale IP.

### 3. Access Services over Tailscale (HTTP)

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

### 4. Enable HTTPS on Port 443 (Optional)

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

---

## Environment Variable Reference

Add these to your `.env` file:

```dotenv
# ============================================================================
# Tailscale Configuration
# ============================================================================

# Auth key from https://login.tailscale.com/admin/settings/keys
# Required for the tailscale container to authenticate automatically.
# Use a reusable key for long-term deployments, or leave empty to authenticate
# manually with: docker exec -it servicepi-tailscale tailscale up
TAILSCALE_AUTH_KEY=

# Tailscale device hostname (shown in the admin console and used as MagicDNS name)
# Default: servicepi
TAILSCALE_HOSTNAME=servicepi

# Whether to accept DNS settings pushed by the tailnet (default: false)
# Set to true if you want Tailscale to manage DNS on the Pi.
TAILSCALE_ACCEPT_DNS=false

# Extra arguments to pass to tailscale up (optional)
# Example: --accept-routes to accept advertised subnet routes
TAILSCALE_EXTRA_ARGS=
```

---

## Manual Authentication

If you prefer not to use an auth key, leave `TAILSCALE_AUTH_KEY` empty and authenticate manually after the container starts:

```bash
docker exec -it servicepi-tailscale tailscale up
```

Follow the URL printed in the terminal to authenticate via the Tailscale admin console.

---

## Troubleshooting

### Check Tailscale status

```bash
docker exec servicepi-tailscale tailscale status
```

### View Tailscale logs

```bash
docker logs servicepi-tailscale
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
- Services are NOT exposed to the public internet. Only devices in your tailnet can access them via the Tailscale IP.
- The UFW firewall rules (`scripts/install.sh`) do not open port 443 to the public internet; Tailscale handles its own NAT traversal.
- Keep `TAILSCALE_AUTH_KEY` secret. Do not commit your `.env` file to version control.
- Private key (`tailscale.key`) is stored in `configs/nginx/certs/` with permissions `600`. Do not commit it.

## Related Documentation

- [README.md](../README.md) - ServicePi overview
- [INSTALL.md](../INSTALL.md) - Installation guide
- [SECURITY.md](../SECURITY.md) - Security considerations
- [Tailscale documentation](https://tailscale.com/kb/)
- [Tailscale Docker guide](https://tailscale.com/kb/1282/docker)

# Domain Name Resolution Setup for ServicePi

This guide explains how to configure local domain name resolution (`.local` domains) for ServicePi services, making them accessible via friendly domain names like `portainer.local` instead of IP addresses with ports.

## Overview

ServicePi supports two methods for accessing services:
1. **IP Address + Port**: `http://192.168.1.100:9000/`
2. **Local Domain Name**: `http://portainer.local:9000/`

Both methods work simultaneously, providing flexibility for different use cases.

## Available Domain Names

Once configured, the following domain names will be available:

| Service | Domain Name | Port | URL Example |
|---------|-------------|------|-------------|
| Web Dashboard | servicepi.local | 80 | http://servicepi.local/ |
| Portainer | portainer.local | 9000 | http://portainer.local:9000/ |
| IoT API | iot.local | 8080 | http://iot.local:8080/ |
| Pi-hole Admin | pihole.local | 8053 | http://pihole.local:8053/admin |
| N8N | n8n.local | 5678 | http://n8n.local:5678/ |
| WordPress* | wordpress.local | 8081 | http://wordpress.local:8081/ |
| Wazuh* | wazuh.local | 8443 | http://wazuh.local:8443/ |

*Optional services - must be enabled separately

## Configuration Methods

### Method 1: Using Pi-hole DNS (Recommended)

This is the recommended method as it provides network-wide domain resolution for all devices.

#### Prerequisites
- Pi-hole must be running
- DNS ports (53/tcp, 53/udp) must be enabled in docker-compose.yml
- Your devices must be configured to use your Pi as their DNS server

#### Step 1: Enable Pi-hole DNS

1. Edit docker-compose.yml:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   ```

2. Uncomment the DNS port mappings in the `pihole` service section:
   ```yaml
   ports:
     - "53:53/tcp"     # DNS TCP
     - "53:53/udp"     # DNS UDP
   ```

3. Update firewall rules:
   ```bash
   sudo ufw allow 53/tcp
   sudo ufw allow 53/udp
   ```

4. Restart Pi-hole:
   ```bash
   cd /opt/servicepi
   sudo docker compose restart pihole
   ```

#### Step 2: Configure Custom DNS Entries

1. Find your Raspberry Pi's IP address:
   ```bash
   hostname -I | awk '{print $1}'
   ```

2. Edit Pi-hole custom DNS entries:
   ```bash
   sudo nano /opt/servicepi/configs/pihole/custom.list
   ```

3. Replace `<YOUR_PI_IP>` with your actual IP address and uncomment all entries:
   ```
   192.168.1.100 servicepi.local
   192.168.1.100 portainer.local
   192.168.1.100 iot.local
   192.168.1.100 pihole.local
   192.168.1.100 n8n.local
   # If using WordPress:
   192.168.1.100 wordpress.local
   # If using Wazuh:
   192.168.1.100 wazuh.local
   ```

4. Restart Pi-hole to apply changes:
   ```bash
   docker compose -f /opt/servicepi/docker-compose.yml restart pihole
   ```

#### Step 3: Configure Your Devices to Use Pi-hole DNS

**Option A: Router-Level Configuration (Recommended)**
1. Log in to your router's admin interface
2. Find DHCP/DNS settings
3. Set primary DNS server to your Pi's IP address
4. Save and reboot router
5. All devices will automatically use Pi-hole for DNS

**Option B: Per-Device Configuration**

**Windows:**
1. Open Network & Internet Settings
2. Click "Change adapter options"
3. Right-click your network adapter → Properties
4. Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties
5. Select "Use the following DNS server addresses"
6. Enter your Pi's IP as Preferred DNS server
7. Click OK

**macOS:**
1. Open System Preferences → Network
2. Select your active connection → Advanced
3. Go to DNS tab
4. Click + and add your Pi's IP address
5. Click OK and Apply

**Linux:**
1. Edit network configuration:
   ```bash
   sudo nano /etc/resolv.conf
   ```
2. Add: `nameserver YOUR_PI_IP`
3. Make it persistent by editing NetworkManager:
   ```bash
   sudo nano /etc/NetworkManager/NetworkManager.conf
   ```
4. Add under `[main]`: `dns=none`

**iOS:**
1. Settings → Wi-Fi
2. Tap (i) next to your network
3. Configure DNS → Manual
4. Add Server: Your Pi's IP
5. Save

**Android:**
1. Settings → Network & Internet → Wi-Fi
2. Long press your network → Modify Network
3. Advanced Options → IP Settings → Static
4. Set DNS 1 to your Pi's IP
5. Save

#### Step 4: Test DNS Resolution

```bash
# From any device on your network:
nslookup portainer.local
ping servicepi.local
```

You should see responses with your Pi's IP address.

### Method 2: Using /etc/hosts Files (Per-Device)

This method doesn't require Pi-hole DNS to be enabled, but must be configured on each device separately.

#### Linux/macOS

1. Edit hosts file:
   ```bash
   sudo nano /etc/hosts
   ```

2. Add entries (replace with your Pi's IP):
   ```
   192.168.1.100 servicepi.local
   192.168.1.100 portainer.local
   192.168.1.100 iot.local
   192.168.1.100 pihole.local
   192.168.1.100 n8n.local
   192.168.1.100 wordpress.local
   192.168.1.100 wazuh.local
   ```

3. Save and exit

#### Windows

1. Run Notepad as Administrator
2. Open: `C:\Windows\System32\drivers\etc\hosts`
3. Add the same entries as above
4. Save the file

#### Test

```bash
ping servicepi.local
```

## Nginx Proxy Configuration

ServicePi's nginx reverse proxy is already configured to handle both IP-based and domain-based requests. Each service is configured with:

```nginx
server_name _ servicepi.local;
```

This means requests to either the IP address or the domain name will be correctly routed to the service.

## Troubleshooting

### Domain names not resolving

1. **Check Pi-hole DNS is running:**
   ```bash
   docker logs servicepi-pihole
   ```

2. **Verify custom.list is configured:**
   ```bash
   cat /opt/servicepi/configs/pihole/custom.list
   ```

3. **Test DNS resolution from Pi itself:**
   ```bash
   dig @localhost servicepi.local
   ```

4. **Check your device's DNS settings:**
   - Ensure it points to your Pi's IP
   - Verify no other DNS servers are listed first

5. **Clear DNS cache on your device:**
   - **Windows:** `ipconfig /flushdns`
   - **macOS:** `sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder`
   - **Linux:** `sudo systemd-resolve --flush-caches`

### Services accessible by IP but not domain name

This indicates a DNS resolution issue:

1. Verify Pi-hole custom.list has correct entries
2. Restart Pi-hole: `docker compose -f /opt/servicepi/docker-compose.yml restart pihole`
3. Check device DNS configuration
4. Try accessing via domain from the Pi itself

### Services accessible by domain but nginx returns wrong service

This indicates an nginx configuration issue:

1. Check nginx configuration:
   ```bash
   docker exec servicepi-proxy nginx -t
   ```

2. Verify proxy configuration:
   ```bash
   cat /opt/servicepi/configs/nginx/proxy/default.conf
   ```

3. Restart nginx proxy:
   ```bash
   docker compose -f /opt/servicepi/docker-compose.yml restart nginx-proxy
   ```

## Using Domain Names with WordPress

WordPress is designed as a user-friendly dashboard for your services. After setting up domain name resolution:

1. Enable and configure WordPress (see README.md)
2. Create pages with links to services using domain names:
   - `http://portainer.local:9000/`
   - etc.

This makes it simple for family members or team members to access services without remembering IP addresses and ports.

## Security Considerations

1. **Local Network Only**: `.local` domains only work within your local network
2. **No Internet Exposure**: These domains don't expose services to the internet
3. **DNS Filtering**: When using Pi-hole DNS, you get ad/tracker blocking as a bonus
4. **HTTPS**: For production use, consider setting up HTTPS with a reverse proxy and Let's Encrypt

## Advanced: Using mDNS/Avahi (Alternative)

For automatic `.local` domain discovery without Pi-hole DNS configuration:

1. Install Avahi on your Pi:
   ```bash
   sudo apt-get install avahi-daemon
   ```

2. Services will be automatically discoverable via Bonjour/mDNS

Note: mDNS works differently than DNS - it's automatic but may not work on all devices/networks. Pi-hole DNS method is more reliable and controllable.

## Summary

- **Best Method**: Use Pi-hole DNS for network-wide domain resolution
- **Fallback**: Use /etc/hosts for per-device configuration
- **Benefits**: Easier access, better user experience, works with WordPress dashboard
- **Requirement**: Must configure DNS or hosts file on each device

For more information, see:
- [Pi-hole Integration Guide](PIHOLE_INTEGRATION.md)
- [Main README](../README.md)

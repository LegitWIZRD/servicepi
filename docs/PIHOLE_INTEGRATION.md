# Pi-hole Integration Summary

This document summarizes the Pi-hole integration into ServicePi.

## Changes Made

### 1. Docker Compose Configuration
**File**: `docker-compose.yml`

Added Pi-hole service with:
- **Container**: `servicepi-pihole` using `pihole/pihole:latest` image
- **DNS Ports**: 53/tcp and 53/udp (commented out by default to avoid conflicts during testing)
- **Admin Port**: Proxied through nginx on port 8053
- **Volumes**: 
  - `pihole_data` for Pi-hole configuration
  - `pihole_dnsmasq` for dnsmasq configuration
  - Mounted blocklists from `configs/pihole/adlists.list`
  - Mounted custom DNS from `configs/pihole/custom.list`
- **Environment Variables**:
  - Default password: `servicepi` (can be overridden with `PIHOLE_PASSWORD`)
  - Upstream DNS: Cloudflare (1.1.1.1 and 1.0.0.1)
  - Timezone: America/New_York

**Important**: The DNS ports (53/tcp and 53/udp) are commented out by default to prevent port conflicts during CI/CD testing and initial setup. To enable network-wide DNS blocking, uncomment these ports in `docker-compose.yml`.

### 2. Pi-hole Configuration Files
**Directory**: `configs/pihole/`

Created three files:

#### `adlists.list` - Curated Blocklists
Includes 7 carefully selected blocklists:
1. **StevenBlack's Unified Hosts** - Comprehensive ad and malware blocking
2. **AdGuard DNS Filter** - Mobile and web ad blocking
3. **EasyList** - Primary ad blocking list
4. **EasyPrivacy** - Tracking and analytics blocking
5. **Peter Lowe's Ad and tracking server list**
6. **Malicious URL Blocklist (URLhaus)** - Malware domain blocking
7. **Phishing Army** - Phishing domain blocklist

#### `custom.list` - Custom DNS Entries
Template file for users to add custom local DNS entries (format: IP domain.name)

#### `README.md` - Documentation
Complete documentation covering:
- Configuration overview
- Blocklist information
- Customization instructions
- Admin interface access
- Troubleshooting tips

### 3. Nginx Reverse Proxy Configuration
**File**: `configs/nginx/proxy/default.conf`

Added Pi-hole admin proxy on port 8053:
```nginx
server {
    listen 8053;
    server_name _;
    location / {
        proxy_pass http://pihole:80;
        # ... proper header forwarding
    }
}
```

Updated nginx-proxy service to expose port 8053.

### 4. Firewall Configuration
**File**: `scripts/install.sh`

Updated UFW firewall rules to allow:
- Port 53/tcp - DNS (TCP)
- Port 53/udp - DNS (UDP)
- Port 8053/tcp - Pi-hole Admin Interface

### 5. Installation Script Updates
**File**: `scripts/install.sh`

Updated to:
- Display Pi-hole access information after installation
- Show Pi-hole admin URL and DNS server address
- Include Pi-hole configuration steps in next steps

### 6. Documentation Updates
**File**: `README.md`

Updated sections:
- **Features**: Added Pi-hole DNS ad blocker feature
- **Access Your Services**: Added Pi-hole admin URL
- **Configure Services**: Added Pi-hole configuration files
- **Repository Structure**: Added pihole config directory
- **Services Included**: Added comprehensive Pi-hole section
- **Security**: Mentioned DNS-level ad and malware blocking
- **Troubleshooting**: Added Pi-hole troubleshooting section

### 7. CI/CD Pipeline Updates
**File**: `.github/workflows/ci-cd.yml`

Updated test suite to:
- Wait for Pi-hole service to start (`FTL started` log message)
- Test Pi-hole admin endpoint (http://localhost:8053/admin)
- Test DNS functionality using `dig` command
- Display Pi-hole logs in case of failures

### 8. Test Script
**File**: `scripts/test-pihole.sh`

Created comprehensive test script that validates:
- Pi-hole container is running
- Admin interface is accessible
- DNS service is responding
- Blocklists are configured
- Custom DNS file exists
- Pi-hole FTL service is running
- Nginx proxy configuration is valid

## Service Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ServicePi Network                        │
│                                                              │
│  ┌──────────────┐    Port 8053    ┌────────────────────┐   │
│  │              │◄─────────────────┤                    │   │
│  │ Nginx Proxy  │                  │   Pi-hole Admin    │   │
│  │              │◄─────────────────┤   (Web Interface)  │   │
│  └──────┬───────┘    Port 80       │                    │   │
│         │                           └────────────────────┘   │
│         │                                                    │
│         │                           ┌────────────────────┐   │
│         │                           │                    │   │
│         └───────────────────────────┤   Pi-hole DNS      │   │
│                                     │   (Port 53)        │   │
│                                     │                    │   │
│                                     └────────────────────┘   │
│                                              ▲               │
└──────────────────────────────────────────────┼───────────────┘
                                               │
                                    Network DNS Queries
                                    (TCP/UDP Port 53)
```

## Usage

### Enable DNS Service (Required for Network-wide Blocking)

By default, DNS ports are commented out. To enable:

1. Edit `docker-compose.yml`:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   ```

2. In the `pihole` service section, uncomment the ports:
   ```yaml
   ports:
     - "53:53/tcp"     # DNS TCP
     - "53:53/udp"     # DNS UDP
   ```

3. Restart Pi-hole:
   ```bash
   docker-compose -f /opt/servicepi/docker-compose.yml up -d pihole
   ```

### Access Pi-hole Admin Interface
```
http://your-pi-ip:8053/admin
Default Password: servicepi
```

### Configure Devices to Use Pi-hole
After enabling DNS ports, set device DNS to: `your-pi-ip`

### Update Blocklists
```bash
docker exec servicepi-pihole pihole -g
```

### View Pi-hole Status
```bash
docker exec servicepi-pihole pihole status
```

### Change Admin Password
```bash
docker exec -it servicepi-pihole pihole -a -p
```

## Compatibility

The Pi-hole integration:
- ✅ Works with existing services (Web Dashboard, Portainer, IoT API)
- ✅ Uses the same network (`servicepi-network`)
- ✅ Follows the same patterns (nginx proxy, volumes, restart policies)
- ✅ Includes firewall configuration
- ✅ Integrated into CI/CD testing
- ✅ Documented in README
- ✅ ARM64 compatible (Raspberry Pi 5)

## Benefits

1. **Network-wide ad blocking** - All devices using Pi-hole DNS get ad blocking
2. **Malware protection** - Blocks known malicious domains
3. **Privacy protection** - Blocks tracking and analytics domains
4. **Centralized management** - Single place to manage DNS for all devices
5. **Curated blocklists** - Automatically applied on installation/updates
6. **Easy customization** - Add/remove blocklists or create custom rules
7. **Integration** - Works seamlessly with other ServicePi services

## Testing

All changes have been validated:
- ✅ Docker Compose configuration syntax
- ✅ Shell script validation (shellcheck)
- ✅ Nginx configuration structure
- ✅ CI/CD pipeline updates
- ✅ Documentation completeness

Full integration test available in `scripts/test-pihole.sh`

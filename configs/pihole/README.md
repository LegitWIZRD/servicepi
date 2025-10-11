# Pi-hole Configuration

This directory contains the configuration for Pi-hole DNS ad-blocker running in ServicePi.

## Files

- `adlists.list` - Curated blocklists automatically applied on installation/update
- `custom.list` - Custom DNS entries (optional)
- `README.md` - This file

## Blocklists

The `adlists.list` file contains carefully selected blocklists that provide comprehensive ad and tracker blocking while minimizing false positives. These lists are automatically applied when Pi-hole starts or during updates.

### Included Blocklists

1. **StevenBlack's Unified Hosts** - Comprehensive ad and malware blocking
2. **AdGuard DNS Filter** - Mobile and web ad blocking
3. **EasyList** - Primary ad blocking list
4. **Malicious URL Blocklist** - Known malicious domains

## Customization

You can add your own blocklists by editing `adlists.list`:

```bash
sudo nano /opt/servicepi/configs/pihole/adlists.list
```

After editing, restart Pi-hole for changes to take effect:

```bash
docker-compose -f /opt/servicepi/docker-compose.yml restart pihole
```

Then update gravity:

```bash
docker exec servicepi-pihole pihole -g
```

## Custom DNS Entries

Add custom local DNS entries to `custom.list`:

```
192.168.1.100 mydevice.local
192.168.1.101 anotherdevice.local
```

## Pi-hole Admin Interface

Access the Pi-hole admin interface at:
- **URL**: `http://your-pi-ip:8053/admin`
- **Default Password**: Set via `WEBPASSWORD` environment variable in `.env` file

To change the password:

```bash
docker exec -it servicepi-pihole pihole -a -p
```

## Notes

- Pi-hole DNS service runs on ports 53 (UDP/TCP)
- Admin interface is proxied through nginx on port 8053
- Configuration and data are persisted in Docker volumes
- Blocklists are updated automatically by Pi-hole's built-in scheduler

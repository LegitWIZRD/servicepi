# Home Assistant Trusted Proxies Fix

## Issue Summary

Users were unable to access Home Assistant after service restarts due to changing Docker bridge network IP addresses. The original configuration only trusted the `172.18.0.0/16` subnet, but Docker bridge networks can use any subnet within the `172.16.0.0/12` range.

## Problem Description

When Docker containers restart or the Docker daemon restarts, the bridge network subnet assignment can change. For example:
- First start: Docker assigns `172.18.0.0/16`
- After restart: Docker assigns `172.19.0.0/16` or `172.20.0.0/16`

With the original configuration trusting only `172.18.0.0/16`, Home Assistant would reject proxy requests from nginx if it was assigned an IP in a different /16 subnet, causing the error:

```
ERROR (MainThread) [homeassistant.components.http.forwarded] A request from a reverse proxy was received from 172.XX.0.X, but your HTTP integration is not set-up for reverse proxies
```

## Solution

Updated the trusted proxies configuration to use the full Docker bridge network range:

**Before:**
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.18.0.0/16  # Docker network range
    - 192.168.0.0/16 # Local network range
    - 10.0.0.0/8     # Private network range
```

**After:**
```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12  # Docker bridge network range (172.16.0.0 - 172.31.255.255)
    - 192.168.0.0/16 # Local network range
    - 10.0.0.0/8     # Private network range
```

## Technical Details

### Docker Bridge Network Ranges

Docker uses the `172.16.0.0/12` CIDR block for bridge networks by default, which includes:
- Starting IP: `172.16.0.0`
- Ending IP: `172.31.255.255`
- Total range: 1,048,576 IP addresses

This is documented in [Docker's official documentation](https://docs.docker.com/network/drivers/bridge/#configure-the-default-bridge-network) and is part of the RFC 1918 private address space.

### Why Not 172.0.0.0/8?

While `172.0.0.0/8` would cover all possible Docker ranges, it would also include non-private ranges:
- `172.0.0.0` - `172.15.255.255` are **not** part of RFC 1918 private address space
- This could potentially create security concerns if those ranges are used elsewhere

The `172.16.0.0/12` range is more precise and secure:
- Covers all standard Docker bridge networks
- Only includes RFC 1918 private address space
- Prevents unnecessary exposure to non-Docker IP ranges

### Security Considerations

The `172.16.0.0/12` range is secure because:
1. It only includes RFC 1918 private addresses that cannot be routed on the public internet
2. It covers the standard Docker bridge network allocation range
3. It's more restrictive than `172.0.0.0/8` while still being broad enough to handle Docker's dynamic IP assignment
4. The other trusted ranges (`192.168.0.0/16` and `10.0.0.0/8`) are also RFC 1918 private networks

## Files Modified

1. **configs/homeassistant/configuration.yaml** - Main Home Assistant configuration
2. **configs/homeassistant/README.md** - Documentation with explanation
3. **docs/CSRF_PROXY_FIX.md** - Updated technical documentation
4. **scripts/test-homeassistant-config.sh** - New test to validate configuration

## Testing

A new test script validates the configuration:

```bash
./scripts/test-homeassistant-config.sh
```

This test verifies:
- ✅ Docker bridge network range (172.16.0.0/12) is configured
- ✅ Local network range (192.168.0.0/16) is configured
- ✅ Private network range (10.0.0.0/8) is configured
- ✅ `use_x_forwarded_for` is enabled
- ✅ YAML syntax is valid

## Deployment

To apply this fix to an existing installation:

1. Pull the latest changes:
   ```bash
   cd /opt/servicepi
   git pull
   ```

2. Restart Home Assistant:
   ```bash
   docker-compose restart homeassistant
   ```

3. Verify the configuration:
   ```bash
   ./scripts/test-homeassistant-config.sh
   ```

## References

- [Docker Bridge Network Driver](https://docs.docker.com/network/drivers/bridge/)
- [RFC 1918 - Private Address Space](https://datatracker.ietf.org/doc/html/rfc1918)
- [Home Assistant HTTP Integration](https://www.home-assistant.io/integrations/http/)
- [Home Assistant Reverse Proxy Guide](https://www.home-assistant.io/docs/configuration/securing/)

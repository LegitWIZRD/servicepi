# N8N Secure Cookie Fix

## Issue Summary

Users were experiencing an error when accessing N8N via HTTP:

```
Your n8n server is configured to use a secure cookie,
however you are either visiting this via an insecure URL, or using Safari.

To fix this, please consider the following options:
    - Setup TLS/HTTPS (recommended), or
    - If you are running this locally, and not using Safari, try using localhost instead
    - If you prefer to disable this security feature (not recommended), 
      set the environment variable N8N_SECURE_COOKIE to false
```

## Root Cause

N8N, by default, sets `N8N_SECURE_COOKIE=true`, which requires HTTPS connections. Since ServicePi is intentionally designed as an HTTP-only system for local network use (as documented in README.md and SECURITY.md), this default setting caused N8N to reject HTTP connections.

## Solution

Added the `N8N_SECURE_COOKIE=false` environment variable to the N8N service configuration in `docker-compose.yml`.

**Changes Made:**

### 1. Docker Compose Configuration
**File**: `docker-compose.yml`

```yaml
n8n:
  image: n8nio/n8n:1.71.0
  container_name: servicepi-n8n
  environment:
    - N8N_HOST=${N8N_HOST:-localhost}
    - N8N_PORT=5678
    - N8N_PROTOCOL=http
    - N8N_SECURE_COOKIE=false  # NEW: Allow HTTP-only access
    - WEBHOOK_URL=${N8N_WEBHOOK_URL:-http://localhost:5678/}
    - GENERIC_TIMEZONE=America/New_York
    - TZ=America/New_York
```

### 2. Test Script
**File**: `scripts/test-n8n-config.sh`

Created a validation script to verify N8N is properly configured for HTTP-only access. The script checks:
- `N8N_SECURE_COOKIE` is set to `false`
- `N8N_PROTOCOL` is set to `http`
- N8N is included in nginx proxy dependencies
- N8N nginx proxy configuration exists
- N8N port 5678 is exposed in nginx proxy

## Technical Details

### Why This Works

N8N uses cookies for session management and authentication. When `N8N_SECURE_COOKIE=true` (the default), N8N sets the `Secure` flag on cookies, which instructs browsers to only send the cookie over HTTPS connections.

By setting `N8N_SECURE_COOKIE=false`, N8N will:
- Not set the `Secure` flag on cookies
- Allow cookies to be sent over HTTP connections
- Work properly in HTTP-only environments like ServicePi

### Security Considerations

ServicePi is designed for local network use only and should NOT be exposed to the internet. The security warnings about using HTTP are valid for public-facing deployments, but acceptable for:

1. **Trusted Local Networks**: All ServicePi services run on a local network behind a router/firewall
2. **No Internet Exposure**: Services are explicitly documented as HTTP-only and unsafe for public access
3. **VPN/SSH Access**: For remote access, users should use VPN (WireGuard, Tailscale) or SSH tunnels

As documented in README.md:
> ⚠️ **Security Warning**: These services are HTTP-only and should ONLY be accessible on your trusted local network. Do NOT expose them directly to the internet. For remote access, use a VPN (WireGuard, Tailscale) or SSH tunnel.

## Testing

The fix has been validated through:

1. **Docker Compose Validation**:
   ```bash
   docker compose config
   ```
   ✅ Configuration syntax is valid

2. **Shell Script Validation**:
   ```bash
   shellcheck scripts/test-n8n-config.sh
   ```
   ✅ No issues found

3. **N8N Configuration Test**:
   ```bash
   ./scripts/test-n8n-config.sh
   ```
   ✅ All checks passed

## Deployment

To apply this fix to an existing ServicePi installation:

1. Pull the latest changes:
   ```bash
   cd /opt/servicepi
   git pull
   ```

2. Restart the N8N service:
   ```bash
   docker-compose restart n8n
   ```

3. Verify the configuration:
   ```bash
   ./scripts/test-n8n-config.sh
   ```

4. Access N8N:
   ```
   http://your-pi-ip:5678
   ```

## Alternative Solutions (Not Implemented)

For users who want to use HTTPS with N8N, the following options exist but are outside the scope of ServicePi's HTTP-only design:

1. **Setup TLS/HTTPS**: Configure nginx with SSL certificates (requires certificate management)
2. **Use Cloudflare Tunnel**: Route traffic through Cloudflare for HTTPS (requires external service)
3. **Reverse Proxy with SSL**: Use an external reverse proxy with SSL termination

These solutions add significant complexity and dependencies that don't align with ServicePi's goal of being a simple, self-contained local network solution.

## Related Documentation

- [README.md](../README.md) - ServicePi HTTP-only architecture
- [SECURITY_IMPLEMENTATION.md](SECURITY_IMPLEMENTATION.md) - Security considerations
- [CSRF_PROXY_FIX.md](CSRF_PROXY_FIX.md) - Related proxy configuration for other services
- [N8N Environment Variables](https://docs.n8n.io/hosting/configuration/environment-variables/) - Official N8N documentation

## References

- [N8N Security Configuration](https://docs.n8n.io/hosting/configuration/environment-variables/)
- [HTTP Cookie Secure Flag](https://developer.mozilla.org/en-US/docs/Web/HTTP/Cookies#restrict_access_to_cookies)
- ServicePi Issue: N8N Integration: Secure Cookie Error

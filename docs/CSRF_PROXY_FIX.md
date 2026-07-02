# CSRF and Proxy Configuration Fix

## Problem Statement

The ServicePi reverse proxy was causing CSRF validation failures in Portainer due to missing or incorrect proxy header configuration.

## Root Causes Identified

1. **Incomplete Header Forwarding**: The proxy was not forwarding critical headers required for CSRF validation:
   - `Origin` header (source of the request)
   - `Referer` header (referrer URL)
   - `X-CSRF-Token` header (CSRF token in custom header)

2. **Cookie Domain Rewriting**: The proxy was modifying cookie domains, breaking session management

3. **Host Header Issues**: Using `$host` instead of `$http_host` omitted the port number, causing origin mismatch

## Solutions Implemented

### 1. Portainer Proxy Configuration

**Before:**
```nginx
proxy_set_header Host $host;
proxy_pass_header Origin;
proxy_pass_header Referer;
```

**After:**
```nginx
# Use $http_host to include port number in Host header
proxy_set_header Host $http_host;

# Explicitly forward CSRF-related headers
proxy_set_header Origin $http_origin;
proxy_set_header Referer $http_referer;
proxy_set_header X-CSRF-Token $http_x_csrf_token;

# Don't modify cookies
proxy_cookie_path / /;
proxy_cookie_domain off;
```

**Why this works:**
- `$http_host` includes the port (e.g., `hostname:9000`), which Portainer needs for origin validation
- Explicitly setting headers ensures they're forwarded even if not in the default proxy headers
- `proxy_cookie_domain off` prevents nginx from rewriting cookie domains
- `proxy_cookie_path / /` preserves the original cookie path

## Technical Details

### CSRF Validation Flow

1. **Client Request**: Browser sends request to `http://hostname:9000/`
2. **Nginx Proxy**: 
   - Receives request with headers: `Origin: http://hostname:9000`, `Referer: http://hostname:9000/dashboard`
   - Forwards these headers to Portainer backend
   - Forwards cookies without modification
3. **Portainer Backend**:
   - Receives all original headers
   - Can validate that Origin/Referer match expected values
   - Can match CSRF token from cookie to token in request
   - Accepts request as valid

### Why `$http_host` vs `$host`

- `$host`: Contains only the hostname (e.g., `pi.local`)
- `$http_host`: Contains hostname AND port from request (e.g., `pi.local:9000`)

Many web applications (including Portainer) validate that the `Host` header matches the origin of the request. When accessing via a non-standard port (like 9000), the port must be included in the Host header for this validation to pass.

### Cookie Handling

**Problem:**
Default nginx behavior rewrites cookie domains to match the proxy domain, which can break session management when the proxy and backend are on different domains/ports.

**Solution:**
- `proxy_cookie_domain off`: Tells nginx not to rewrite the cookie domain
- `proxy_cookie_path / /`: Preserves the original cookie path

This ensures cookies set by the backend service are sent back to the client unmodified, and the client will send them back on subsequent requests.

## Testing

### Automated Tests (CI/CD)
- Endpoint accessibility tests for all services
- Proxy header forwarding validation
- Nginx configuration syntax validation

### Manual Tests
Run the test script:
```bash
/opt/servicepi/scripts/test-proxy-headers.sh
```

### Validation Commands
```bash
# Check nginx config syntax
docker exec servicepi-proxy nginx -t

# View proxy logs
docker logs servicepi-proxy

# Test Portainer with headers
curl -v -H "Origin: http://test.com" http://localhost:9000/
```

## References

- Nginx proxy_set_header: http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_set_header
- Nginx cookie directives: http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_cookie_domain
- Portainer documentation: https://docs.portainer.io/

## Related Issues

This fix addresses the issues described in the GitHub issue regarding:
- CSRF validation failures when saving via Portainer
- Missing or incorrect proxy headers
- Cookie and session management issues

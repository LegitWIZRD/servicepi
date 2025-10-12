# Home Assistant Configuration

This directory contains the base configuration for Home Assistant running behind the ServicePi reverse proxy.

## Files

- `configuration.yaml` - Main Home Assistant configuration file

## Key Configuration

The configuration file sets up Home Assistant to work properly behind the nginx reverse proxy:

### Trusted Proxies

```yaml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 172.16.0.0/12  # Docker bridge network range (172.16.0.0 - 172.31.255.255)
    - 192.168.0.0/16 # Local network range
    - 10.0.0.0/8     # Private network range
```

This configuration:
- Enables `use_x_forwarded_for` to accept X-Forwarded-For headers from trusted proxies
- Trusts the entire Docker bridge network range (172.16.0.0/12) to handle dynamic IP assignments
- Trusts common private network ranges for external proxies

### Why This is Needed

When Home Assistant receives requests from the nginx reverse proxy, it sees the proxy's IP address (e.g., 172.18.0.6) instead of the client's IP. Without this configuration, Home Assistant logs errors like:

```
ERROR (MainThread) [homeassistant.components.http.forwarded] A request from a reverse proxy was received from 172.18.0.6, but your HTTP integration is not set-up for reverse proxies
```

The `trusted_proxies` configuration tells Home Assistant that requests from these IP ranges are legitimate and should use the X-Forwarded-For header to determine the actual client IP.

**Why 172.16.0.0/12?** Docker bridge networks use the 172.16.0.0 - 172.31.255.255 range (172.16.0.0/12). When containers restart or the Docker daemon restarts, the network subnet may change within this range (e.g., from 172.18.0.0/16 to 172.19.0.0/16). Using the full /12 range ensures Home Assistant works regardless of which subnet Docker assigns.

## Customization

You can add additional Home Assistant configuration options to `configuration.yaml`. See the [Home Assistant documentation](https://www.home-assistant.io/docs/configuration/) for all available options.

Common additions:
- Automations
- Integrations
- Themes
- Users and authentication

## Notes

- The configuration.yaml file is mounted into the Home Assistant container at startup
- Changes to this file require restarting the Home Assistant container
- Other Home Assistant files (automations, scripts, etc.) are stored in the Docker volume `homeassistant_data`

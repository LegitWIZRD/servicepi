#!/bin/bash

# setup-tailscale-certs.sh
# Provisions Tailscale TLS certificates and activates HTTPS in nginx.
#
# This script:
#   1. Checks that host Tailscale is installed and authenticated.
#   2. Requests a TLS certificate for the Tailscale MagicDNS hostname via 'tailscale cert'.
#   3. Copies the certificate and key to configs/nginx/certs/.
#   4. Activates the HTTPS nginx config (https.conf.template → https.conf).
#   5. Reloads nginx to apply the new configuration.
#
# Prerequisites:
#   - docker compose up -d (all services running)
#   - Tailscale installed on the host and authenticated (`tailscale up`)
#   - Tailscale HTTPS Certificates enabled in your tailnet admin console:
#       https://login.tailscale.com/admin/dns (enable "HTTPS Certificates")
#
# Usage:
#   sudo bash scripts/setup-tailscale-certs.sh [--domain <tailscale-hostname.ts.net>]
#
# Example:
#   sudo bash scripts/setup-tailscale-certs.sh
#   sudo bash scripts/setup-tailscale-certs.sh --domain servicepi.tailnet-name.ts.net

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()     { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# Parse arguments
DOMAIN=""
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --domain) DOMAIN="$2"; shift ;;
        *) error "Unknown parameter: $1" ;;
    esac
    shift
done

# Determine script location (works when run from any directory)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICEPI_DIR="$(dirname "$SCRIPT_DIR")"
CERTS_DIR="$SERVICEPI_DIR/configs/nginx/certs"
PROXY_DIR="$SERVICEPI_DIR/configs/nginx/proxy"

log "ServicePi Tailscale Certificate Setup"
echo ""

# Check that docker is available
if ! command -v docker &>/dev/null; then
    error "Docker is not installed or not in PATH."
fi

# Check that tailscale is installed on the host
if ! command -v tailscale &>/dev/null; then
    error "Tailscale is not installed on the host. Install Tailscale, run 'sudo tailscale up' to authenticate, then rerun this script."
fi

# Use sudo for tailscale operations when available and not already root
TAILSCALE_CMD=(tailscale)
if [ "$EUID" -ne 0 ] && command -v sudo &>/dev/null; then
    TAILSCALE_CMD=(sudo tailscale)
fi

# Capture host tailscale status
TS_STATUS_JSON="$("${TAILSCALE_CMD[@]}" status --json 2>/dev/null || true)"
if [ -z "$TS_STATUS_JSON" ]; then
    error "Unable to read Tailscale status. Ensure host Tailscale is running/authenticated and retry (for example: tailscale status, tailscale up)."
fi

# Determine the Tailscale hostname/domain if not provided
if [ -z "$DOMAIN" ]; then
    log "Detecting Tailscale hostname..."
    # Prefer jq for reliable JSON parsing; fall back to grep/sed if not available
    if command -v jq &>/dev/null; then
        DOMAIN=$(printf '%s' "$TS_STATUS_JSON" | jq -r '.Self.DNSName // empty' 2>/dev/null | sed 's/\.$//' || true)
    else
        DOMAIN=$(printf '%s' "$TS_STATUS_JSON" | grep -o '"DNSName":"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/\.$//' || true)
    fi

    if [ -z "$DOMAIN" ]; then
        error "Could not auto-detect Tailscale domain. Ensure host Tailscale is authenticated, or pass --domain <hostname.ts.net>."
    fi
fi

log "Using Tailscale domain: ${DOMAIN}"

# Ensure HTTPS Certificates are enabled in the tailnet
log "Requesting TLS certificate from Tailscale..."
mkdir -p "$CERTS_DIR"
TMP_CERT="$CERTS_DIR/tailscale.crt.tmp"
TMP_KEY="$CERTS_DIR/tailscale.key.tmp"
OLD_UMASK="$(umask)"
if ! umask 077; then
    error "Failed to set secure file permissions for certificate generation."
fi
restore_umask() { umask "$OLD_UMASK"; }
trap restore_umask EXIT

if ! "${TAILSCALE_CMD[@]}" cert --cert-file "$TMP_CERT" --key-file "$TMP_KEY" "$DOMAIN"; then
    echo ""
    warning "Certificate request failed. Check that:"
    echo "  1. HTTPS Certificates are enabled in your tailnet:"
    echo "       https://login.tailscale.com/admin/dns  →  'HTTPS Certificates'"
    echo "  2. Host Tailscale is authenticated (check: tailscale status; if needed, run tailscale up)."
    echo "  3. The domain '${DOMAIN}' matches your tailnet hostname."
    error "Certificate provisioning failed."
fi

# Move certs into expected nginx filenames
mv "$TMP_CERT" "$CERTS_DIR/tailscale.crt"
mv "$TMP_KEY" "$CERTS_DIR/tailscale.key"

# Secure the private key
chmod 600 "$CERTS_DIR/tailscale.key"
chmod 644 "$CERTS_DIR/tailscale.crt"

success "Certificates saved to ${CERTS_DIR}/"

# Activate the HTTPS nginx config by copying the template
TEMPLATE="$PROXY_DIR/https.conf.template"
HTTPS_CONF="$PROXY_DIR/https.conf"

if [ ! -f "$TEMPLATE" ]; then
    error "HTTPS nginx config template not found at: ${TEMPLATE}"
fi

log "Activating HTTPS nginx configuration..."
cp "$TEMPLATE" "$HTTPS_CONF"
success "https.conf activated in ${PROXY_DIR}/"

# Test and reload nginx
log "Testing nginx configuration..."
if docker exec servicepi-proxy nginx -t; then
    log "Reloading nginx..."
    docker exec servicepi-proxy nginx -s reload
    success "nginx reloaded with HTTPS support."
else
    error "nginx configuration test failed. Check the HTTPS config template."
fi

echo ""
success "Tailscale HTTPS setup complete!"
echo ""
echo "  Web dashboard (local HTTP)      : http://$(hostname -I | awk '{print $1}')/"
echo "  Web dashboard (Tailscale HTTPS) : https://${DOMAIN}/"
echo "  Portainer     (Tailscale HTTPS) : https://${DOMAIN}:9000/"
echo "  IoT API       (Tailscale HTTPS) : https://${DOMAIN}:8080/"
echo "  Home Assistant (Tailscale HTTPS) : https://${DOMAIN}:8123/"
echo "  Pi-hole Admin (Tailscale HTTPS) : https://${DOMAIN}:8053/"
echo "  N8N           (Tailscale HTTPS) : https://${DOMAIN}:5678/"
echo "  WordPress     (Tailscale HTTPS) : https://${DOMAIN}:8081/"
echo "  OpenWebUI     (Tailscale HTTPS) : https://${DOMAIN}:3000/"
echo "  SearXNG       (Tailscale HTTPS) : https://${DOMAIN}:8888/"
echo ""
echo "Notes:"
echo "  - Certificate auto-renewal: re-run this script before the cert expires (90 days)."
echo "  - To disable HTTPS, remove ${PROXY_DIR}/https.conf and reload nginx."
echo "  - All services above are served over HTTPS using the same Tailscale certificate."
echo "  - Local LAN access continues to use HTTP on the original ports (unchanged)."
echo ""
echo "See docs/TAILSCALE_SETUP.md for full documentation."

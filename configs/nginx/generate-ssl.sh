#!/bin/bash

# SSL Certificate Generation Script for ServicePi
# Creates self-signed certificates for local development or Let's Encrypt certificates for production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SSL_DIR="$SCRIPT_DIR/ssl"
DOMAIN="${1:-localhost}"
MODE="${2:-self-signed}"  # self-signed or letsencrypt

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[SSL]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Create SSL directories
create_ssl_dirs() {
    log "Creating SSL certificate directories..."
    mkdir -p "$SSL_DIR"/{web,portainer,iot}
}

# Generate self-signed certificates
generate_self_signed() {
    local service="$1"
    local service_dir="$SSL_DIR/$service"
    
    log "Generating self-signed certificate for $service..."
    
    # Create service-specific certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout "$service_dir/privkey.pem" \
        -out "$service_dir/fullchain.pem" \
        -subj "/C=US/ST=Local/L=Local/O=ServicePi/OU=IT/CN=$DOMAIN" \
        -addext "subjectAltName=DNS:$DOMAIN,DNS:localhost,IP:192.168.1.100,IP:127.0.0.1"
    
    # Set appropriate permissions
    chmod 600 "$service_dir/privkey.pem"
    chmod 644 "$service_dir/fullchain.pem"
    
    success "Self-signed certificate created for $service"
}

# Generate Let's Encrypt certificates
generate_letsencrypt() {
    local service="$1"
    local service_dir="$SSL_DIR/$service"
    
    log "Generating Let's Encrypt certificate for $service on domain $DOMAIN..."
    
    # Check if docker-compose is available
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is required for Let's Encrypt certificate generation"
    fi
    
    # Create webroot directory
    mkdir -p "$SCRIPT_DIR/certbot-webroot"
    
    # Run certbot to get certificate
    docker run --rm \
        -v "$SSL_DIR:/etc/letsencrypt" \
        -v "$SCRIPT_DIR/certbot-webroot:/var/www/certbot" \
        certbot/certbot:latest certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email admin@"$DOMAIN" \
        --agree-tos \
        --no-eff-email \
        -d "$DOMAIN"
    
    # Copy certificates to service directory
    if [ -d "$SSL_DIR/live/$DOMAIN" ]; then
        cp "$SSL_DIR/live/$DOMAIN/fullchain.pem" "$service_dir/"
        cp "$SSL_DIR/live/$DOMAIN/privkey.pem" "$service_dir/"
        success "Let's Encrypt certificate created for $service"
    else
        error "Failed to generate Let's Encrypt certificate for $DOMAIN"
    fi
}

# Main certificate generation
generate_certificates() {
    log "Starting SSL certificate generation..."
    log "Domain: $DOMAIN"
    log "Mode: $MODE"
    
    create_ssl_dirs
    
    # Generate certificates for each service
    for service in web portainer iot; do
        case $MODE in
            "self-signed")
                generate_self_signed "$service"
                ;;
            "letsencrypt")
                generate_letsencrypt "$service"
                ;;
            *)
                error "Invalid mode: $MODE. Use 'self-signed' or 'letsencrypt'"
                ;;
        esac
    done
    
    success "All SSL certificates generated successfully!"
}

# Certificate renewal (for Let's Encrypt)
renew_certificates() {
    if [ "$MODE" != "letsencrypt" ]; then
        warning "Certificate renewal is only applicable for Let's Encrypt certificates"
        return
    fi
    
    log "Renewing Let's Encrypt certificates..."
    
    docker run --rm \
        -v "$SSL_DIR:/etc/letsencrypt" \
        -v "$SCRIPT_DIR/certbot-webroot:/var/www/certbot" \
        certbot/certbot:latest renew
    
    # Copy renewed certificates
    for service in web portainer iot; do
        if [ -d "$SSL_DIR/live/$DOMAIN" ]; then
            cp "$SSL_DIR/live/$DOMAIN/fullchain.pem" "$SSL_DIR/$service/"
            cp "$SSL_DIR/live/$DOMAIN/privkey.pem" "$SSL_DIR/$service/"
        fi
    done
    
    success "Certificates renewed successfully!"
}

# Help function
show_help() {
    echo "ServicePi SSL Certificate Generator"
    echo ""
    echo "Usage: $0 [domain] [mode] [action]"
    echo ""
    echo "Parameters:"
    echo "  domain    Domain name (default: localhost)"
    echo "  mode      Certificate mode: self-signed|letsencrypt (default: self-signed)"
    echo ""
    echo "Actions:"
    echo "  generate  Generate new certificates (default)"
    echo "  renew     Renew existing Let's Encrypt certificates"
    echo "  help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                              # Generate self-signed certs for localhost"
    echo "  $0 mypi.local self-signed      # Generate self-signed certs for mypi.local"
    echo "  $0 pi.example.com letsencrypt  # Generate Let's Encrypt certs"
    echo "  $0 pi.example.com letsencrypt renew  # Renew Let's Encrypt certs"
}

# Handle script arguments
ACTION="${3:-generate}"

case "$ACTION" in
    "generate")
        generate_certificates
        ;;
    "renew")
        renew_certificates
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        error "Unknown action: $ACTION. Use 'generate', 'renew', or 'help'"
        ;;
esac
#!/bin/bash

# ServicePi Installation Script
# Run this script on your Raspberry Pi to set up the initial installation

set -e

# Configuration
REPO_URL="https://github.com/LegitWIZRD/servicepi.git"
INSTALL_DIR="/opt/servicepi"
SERVICE_USER="servicepi"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
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

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    error "This script must be run as root (use sudo)"
fi

log "Starting ServicePi installation..."

# Update system
log "Updating system packages..."
apt update && apt upgrade -y

# Install required packages
log "Installing required packages..."
apt install -y \
    docker.io \
    docker-compose \
    git \
    curl \
    wget \
    nano \
    htop \
    ufw

# Start and enable Docker
log "Starting Docker service..."
systemctl start docker
systemctl enable docker

# Create service user
if ! id "$SERVICE_USER" &>/dev/null; then
    log "Creating service user: $SERVICE_USER"
    useradd -r -s /bin/bash -d /home/$SERVICE_USER -m $SERVICE_USER
    usermod -aG docker $SERVICE_USER
else
    log "Service user $SERVICE_USER already exists"
fi

# Clone repository
log "Cloning ServicePi repository..."
if [ -d "$INSTALL_DIR" ]; then
    warning "Installation directory already exists, updating..."
    cd "$INSTALL_DIR"
    git pull
else
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# Set permissions
log "Setting up permissions..."
chown -R $SERVICE_USER:$SERVICE_USER "$INSTALL_DIR"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# Create systemd service for auto-updates (optional)
log "Creating systemd service for ServicePi..."
cat > /etc/systemd/system/servicepi-update.service << EOF
[Unit]
Description=ServicePi Update Service
After=network.target docker.service

[Service]
Type=oneshot
User=root
ExecStart=$INSTALL_DIR/scripts/update-pi.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Create timer for periodic updates (optional)
cat > /etc/systemd/system/servicepi-update.timer << EOF
[Unit]
Description=ServicePi Update Timer
Requires=servicepi-update.service

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Enable services
systemctl daemon-reload
systemctl enable servicepi-update.service

# Configure firewall
log "Configuring firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp  # Web server
ufw allow 9000/tcp  # Portainer
ufw --force enable

# Initial deployment
log "Starting initial deployment..."
cd "$INSTALL_DIR"
docker-compose pull
docker-compose up -d

# Wait for services to start
sleep 10

# Check status
log "Checking service status..."
docker-compose ps

success "ServicePi installation completed!"
echo ""
echo "🎉 Installation Summary:"
echo "  - Installation directory: $INSTALL_DIR"
echo "  - Service user: $SERVICE_USER"
echo "  - Auto-update service: enabled (daily)"
echo "  - Web dashboard: http://$(hostname -I | awk '{print $1}')"
echo "  - Portainer: http://$(hostname -I | awk '{print $1}'):9000"
echo ""
echo "📝 Next steps:"
echo "  1. Access the web dashboard to verify installation"
echo "  2. Configure Portainer (first-time setup)"
echo "  3. Customize services in docker-compose.yml as needed"
echo "  4. Set up automatic updates with 'sudo systemctl enable --now servicepi-update.timer'"
echo ""
echo "🔧 Useful commands:"
echo "  - Manual update: sudo $INSTALL_DIR/scripts/update-pi.sh"
echo "  - View logs: docker-compose -f $INSTALL_DIR/docker-compose.yml logs"
echo "  - Restart services: docker-compose -f $INSTALL_DIR/docker-compose.yml restart"
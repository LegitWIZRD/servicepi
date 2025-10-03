#!/bin/bash

# ServicePi Update Script
# This script pulls the latest configurations and updates Docker containers

set -e

# Configuration
REPO_URL="https://github.com/LegitWIZRD/servicepi.git"
INSTALL_DIR="/opt/servicepi"
LOG_FILE="/var/log/servicepi-update.log"
BACKUP_DIR="/opt/servicepi-backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
    echo -e "${RED}ERROR: $1${NC}" | tee -a "$LOG_FILE"
    exit 1
}

# Success message
success() {
    echo -e "${GREEN}SUCCESS: $1${NC}" | tee -a "$LOG_FILE"
}

# Warning message
warning() {
    echo -e "${YELLOW}WARNING: $1${NC}" | tee -a "$LOG_FILE"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error_exit "This script must be run as root (use sudo)"
    fi
}

# Create backup of current configuration
create_backup() {
    log "Creating backup of current configuration..."
    
    if [ -d "$INSTALL_DIR" ]; then
        BACKUP_NAME="servicepi-backup-$(date '+%Y%m%d-%H%M%S')"
        mkdir -p "$BACKUP_DIR"
        cp -r "$INSTALL_DIR" "$BACKUP_DIR/$BACKUP_NAME"
        success "Backup created at $BACKUP_DIR/$BACKUP_NAME"
    else
        warning "No existing installation found to backup"
    fi
}

# Pull latest repository changes
update_repo() {
    log "Updating repository..."
    
    if [ -d "$INSTALL_DIR/.git" ]; then
        cd "$INSTALL_DIR"
        git fetch origin
        git reset --hard origin/main
        success "Repository updated successfully"
    else
        log "Cloning repository for first time..."
        mkdir -p "$(dirname "$INSTALL_DIR")"
        git clone "$REPO_URL" "$INSTALL_DIR"
        success "Repository cloned successfully"
    fi
}

# Update Docker containers
update_containers() {
    log "Updating Docker containers..."
    
    cd "$INSTALL_DIR"
    
    # Pull latest images
    docker-compose pull
    
    # Stop and recreate containers with new configurations
    docker-compose down
    docker-compose up -d
    
    # Clean up old images
    docker image prune -f
    
    success "Docker containers updated successfully"
}

# Check container health
check_health() {
    log "Checking container health..."
    
    cd "$INSTALL_DIR"
    
    # Wait a bit for containers to start
    sleep 10
    
    # Check if all services are running
    if docker-compose ps | grep -q "Exit"; then
        warning "Some containers may have failed to start"
        docker-compose ps
    else
        success "All containers are running"
    fi
}

# Main update process
main() {
    log "Starting ServicePi update process..."
    
    check_root
    create_backup
    update_repo
    update_containers
    check_health
    
    success "ServicePi update completed successfully!"
    log "Update process finished"
}

# Handle script arguments
case "${1:-}" in
    --dry-run)
        log "DRY RUN: Would update ServicePi installation"
        echo "This would:"
        echo "1. Create backup of current configuration"
        echo "2. Pull latest repository changes"
        echo "3. Update Docker containers"
        echo "4. Check container health"
        ;;
    --backup-only)
        log "Creating backup only..."
        check_root
        create_backup
        ;;
    --help|-h)
        echo "ServicePi Update Script"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  --dry-run       Show what would be done without making changes"
        echo "  --backup-only   Create backup without updating"
        echo "  --help, -h      Show this help message"
        echo ""
        echo "Default: Run full update process"
        ;;
    *)
        main
        ;;
esac
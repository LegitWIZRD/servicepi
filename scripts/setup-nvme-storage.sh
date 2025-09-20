#!/bin/bash

# ServicePi NVMe Storage Setup Script
# Detects and formats an NVMe drive for Docker container storage

set -e

# Configuration
NVME_MOUNT_POINT="/opt/docker-storage"
DOCKER_DATA_ROOT="$NVME_MOUNT_POINT/docker"
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[NVME-SETUP]${NC} $1"
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
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
    fi
}

# Detect NVMe drives (excluding boot drive)
detect_nvme_drives() {
    log "Detecting NVMe drives..."
    
    # Get root device to avoid formatting boot drive
    ROOT_DEVICE=$(findmnt -n -o SOURCE / | sed 's/[0-9]*$//')
    ROOT_DEVICE=$(basename "$ROOT_DEVICE")
    
    log "Root device detected: $ROOT_DEVICE"
    
    # Find NVMe drives that are not the root device
    NVME_DRIVES=()
    for drive in /dev/nvme*n1; do
        if [ -e "$drive" ]; then
            drive_name=$(basename "$drive")
            # Skip if this is the root device
            if [[ "$drive_name" != "$ROOT_DEVICE"* ]]; then
                NVME_DRIVES+=("$drive")
            fi
        fi
    done
    
    if [ ${#NVME_DRIVES[@]} -eq 0 ]; then
        warning "No additional NVMe drives found (excluding boot drive)"
        warning "ServicePi will use default Docker storage location"
        return 1
    fi
    
    log "Found ${#NVME_DRIVES[@]} additional NVMe drive(s):"
    for drive in "${NVME_DRIVES[@]}"; do
        drive_size=$(lsblk -b -d -o SIZE "$drive" 2>/dev/null | tail -n1 | numfmt --to=iec)
        log "  - $drive ($drive_size)"
    done
    
    return 0
}

# Get user confirmation for drive formatting
confirm_format() {
    local selected_drive="$1"
    
    echo ""
    warning "⚠️  IMPORTANT: This will COMPLETELY ERASE the selected drive!"
    warning "Drive to be formatted: $selected_drive"
    
    # Show drive information
    log "Drive information:"
    lsblk "$selected_drive" 2>/dev/null || true
    
    echo ""
    echo -n "Are you absolutely sure you want to format $selected_drive? (yes/no): "
    read -r response
    
    if [[ "$response" != "yes" ]]; then
        log "Drive formatting cancelled by user"
        return 1
    fi
    
    echo -n "Type 'FORMAT' to confirm: "
    read -r confirm
    
    if [[ "$confirm" != "FORMAT" ]]; then
        log "Drive formatting cancelled - confirmation failed"
        return 1
    fi
    
    return 0
}

# Select drive to format
select_drive() {
    if [ ${#NVME_DRIVES[@]} -eq 1 ]; then
        SELECTED_DRIVE="${NVME_DRIVES[0]}"
        log "Automatically selected single drive: $SELECTED_DRIVE"
    else
        echo ""
        log "Multiple NVMe drives detected. Please select one:"
        for i in "${!NVME_DRIVES[@]}"; do
            drive="${NVME_DRIVES[$i]}"
            drive_size=$(lsblk -b -d -o SIZE "$drive" 2>/dev/null | tail -n1 | numfmt --to=iec)
            echo "  $((i+1)). $drive ($drive_size)"
        done
        
        echo -n "Enter selection (1-${#NVME_DRIVES[@]}): "
        read -r selection
        
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#NVME_DRIVES[@]} ]; then
            error "Invalid selection"
        fi
        
        SELECTED_DRIVE="${NVME_DRIVES[$((selection-1))]}"
    fi
    
    log "Selected drive: $SELECTED_DRIVE"
}

# Format the selected drive
format_drive() {
    log "Unmounting any existing partitions on $SELECTED_DRIVE..."
    umount "${SELECTED_DRIVE}"* 2>/dev/null || true
    
    log "Wiping existing partition table..."
    wipefs -a "$SELECTED_DRIVE"
    
    log "Creating new partition table..."
    parted -s "$SELECTED_DRIVE" mklabel gpt
    
    log "Creating single partition..."
    parted -s "$SELECTED_DRIVE" mkpart primary ext4 0% 100%
    
    # Wait for partition to be recognized
    sleep 2
    partprobe "$SELECTED_DRIVE"
    sleep 2
    
    # Determine partition name
    PARTITION="${SELECTED_DRIVE}p1"
    if [ ! -e "$PARTITION" ]; then
        PARTITION="${SELECTED_DRIVE}1"
    fi
    
    log "Formatting partition $PARTITION with ext4..."
    mkfs.ext4 -F "$PARTITION"
    
    log "Setting filesystem label..."
    e2label "$PARTITION" "docker-storage"
    
    success "Drive formatted successfully"
    FORMATTED_PARTITION="$PARTITION"
}

# Mount the drive and update fstab
setup_mount() {
    log "Creating mount point: $NVME_MOUNT_POINT"
    mkdir -p "$NVME_MOUNT_POINT"
    
    log "Mounting $FORMATTED_PARTITION to $NVME_MOUNT_POINT"
    mount "$FORMATTED_PARTITION" "$NVME_MOUNT_POINT"
    
    # Get UUID for fstab entry
    DRIVE_UUID=$(blkid -s UUID -o value "$FORMATTED_PARTITION")
    
    log "Adding permanent mount to /etc/fstab (UUID: $DRIVE_UUID)"
    
    # Remove any existing entry for this mount point
    sed -i "\\|$NVME_MOUNT_POINT|d" /etc/fstab
    
    # Add new entry
    echo "UUID=$DRIVE_UUID $NVME_MOUNT_POINT ext4 defaults,noatime 0 2" >> /etc/fstab
    
    success "Drive mounted and added to fstab"
}

# Configure Docker to use the NVMe drive
configure_docker() {
    log "Creating Docker data directory: $DOCKER_DATA_ROOT"
    mkdir -p "$DOCKER_DATA_ROOT"
    
    log "Configuring Docker daemon to use NVMe storage..."
    
    # Create or update Docker daemon configuration
    if [ -f "$DOCKER_DAEMON_CONFIG" ]; then
        # Backup existing config
        cp "$DOCKER_DAEMON_CONFIG" "${DOCKER_DAEMON_CONFIG}.backup.$(date +%Y%m%d-%H%M%S)"
        log "Backed up existing Docker daemon config"
    fi
    
    # Create new daemon config
    cat > "$DOCKER_DAEMON_CONFIG" << EOF
{
    "data-root": "$DOCKER_DATA_ROOT",
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
EOF
    
    success "Docker daemon configured to use NVMe storage"
}

# Set appropriate permissions
set_permissions() {
    log "Setting appropriate permissions..."
    
    # Set ownership to service user if it exists
    if id "servicepi" &>/dev/null; then
        chown -R servicepi:servicepi "$NVME_MOUNT_POINT"
    fi
    
    # Ensure Docker data directory has correct permissions
    chmod 755 "$DOCKER_DATA_ROOT"
    
    success "Permissions set"
}

# Main function
main() {
    log "Starting NVMe storage setup for ServicePi..."
    
    check_root
    
    if ! detect_nvme_drives; then
        log "No additional NVMe drives found - skipping NVMe setup"
        exit 0
    fi
    
    select_drive
    
    if ! confirm_format "$SELECTED_DRIVE"; then
        log "NVMe setup cancelled by user"
        exit 0
    fi
    
    format_drive
    setup_mount
    configure_docker
    set_permissions
    
    success "NVMe storage setup completed successfully!"
    echo ""
    log "Summary:"
    log "  - Formatted drive: $SELECTED_DRIVE"
    log "  - Mount point: $NVME_MOUNT_POINT"
    log "  - Docker data root: $DOCKER_DATA_ROOT"
    log "  - Configuration: $DOCKER_DAEMON_CONFIG"
    echo ""
    warning "Note: Docker service will need to be restarted to use new storage location"
}

# Handle script arguments
case "${1:-}" in
    "help"|"-h"|"--help")
        echo "ServicePi NVMe Storage Setup Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  (no args)   Run interactive NVMe setup"
        echo "  help        Show this help message"
        echo ""
        echo "This script will:"
        echo "  1. Detect available NVMe drives (excluding boot drive)"
        echo "  2. Allow user to select and confirm drive formatting"
        echo "  3. Format selected drive with ext4 filesystem"
        echo "  4. Mount drive to $NVME_MOUNT_POINT"
        echo "  5. Configure Docker to use NVMe storage"
        echo ""
        echo "Safety features:"
        echo "  - Automatically excludes boot/root drive"
        echo "  - Requires explicit user confirmation"
        echo "  - Shows drive information before formatting"
        ;;
    *)
        main "$@"
        ;;
esac
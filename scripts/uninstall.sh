#!/bin/bash

# ServicePi Uninstall Script
# Provides partial removal with data intact or full removal with storage cleanup

set -e

# Configuration
INSTALL_DIR="/opt/servicepi"
SERVICE_USER="servicepi"
UPDATE_SERVICE="/etc/systemd/system/servicepi-update.service"
UPDATE_TIMER="/etc/systemd/system/servicepi-update.timer"
NVME_MOUNT_POINT="/opt/docker-storage"
DOCKER_DAEMON_CONFIG="/etc/docker/daemon.json"

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

check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root (use sudo)"
    fi
}

confirm() {
    local prompt="$1"
    local response

    read -r -p "$prompt (yes/no): " response
    [ "$response" = "yes" ]
}

compose_cmd() {
    if command -v docker-compose >/dev/null 2>&1; then
        docker-compose "$@"
    elif docker compose version >/dev/null 2>&1; then
        docker compose "$@"
    else
        error "Docker Compose is not installed"
    fi
}

stop_containers() {
    local remove_volumes="${1:-false}"

    if [ -d "$INSTALL_DIR" ]; then
        log "Stopping ServicePi containers..."
        cd "$INSTALL_DIR"
        if [ "$remove_volumes" = true ]; then
            if compose_cmd down -v --remove-orphans; then
                success "ServicePi containers and volumes removed"
            else
                warning "Docker Compose shutdown reported an issue, continuing cleanup"
            fi
        elif compose_cmd down --remove-orphans; then
            success "ServicePi containers stopped"
        else
            warning "Docker Compose shutdown reported an issue, continuing cleanup"
        fi
    else
        warning "Installation directory not found, skipping Docker Compose shutdown"
    fi
}

remove_containers_by_name() {
    local containers

    containers="$(docker ps -aq --filter 'name=^servicepi-' || true)"
    if [ -n "$containers" ]; then
        log "Removing remaining ServicePi containers..."
        while IFS= read -r container; do
            if [ -n "$container" ]; then
                docker rm -f "$container" >/dev/null 2>&1 || true
            fi
        done <<EOF
$containers
EOF
        success "Remaining ServicePi containers removed"
    fi
}

remove_update_services() {
    log "Removing ServicePi update service..."
    systemctl disable --now servicepi-update.timer >/dev/null 2>&1 || true
    systemctl disable --now servicepi-update.service >/dev/null 2>&1 || true
    rm -f "$UPDATE_SERVICE" "$UPDATE_TIMER"
    systemctl daemon-reload
    success "ServicePi update service removed"
}

remove_service_user() {
    if id "$SERVICE_USER" >/dev/null 2>&1; then
        log "Removing service user: $SERVICE_USER"
        userdel -r "$SERVICE_USER" >/dev/null 2>&1 || userdel "$SERVICE_USER"
        success "Service user removed"
    fi
}

remove_installation() {
    if [ -d "$INSTALL_DIR" ]; then
        log "Removing installation directory: $INSTALL_DIR"
        rm -rf "$INSTALL_DIR"
        success "Installation directory removed"
    fi
}

resolve_storage_device() {
    local source_device fstab_line fstab_spec

    source_device="$(findmnt -n -o SOURCE "$NVME_MOUNT_POINT" 2>/dev/null || true)"
    if [ -n "$source_device" ]; then
        echo "$source_device"
        return 0
    fi

    fstab_line="$(grep -E "[[:space:]]${NVME_MOUNT_POINT}[[:space:]]" /etc/fstab 2>/dev/null | tail -n1 || true)"
    if [ -z "$fstab_line" ]; then
        return 0
    fi

    fstab_spec="$(echo "$fstab_line" | awk '{print $1}')"
    case "$fstab_spec" in
        UUID=*)
            blkid -U "${fstab_spec#UUID=}" 2>/dev/null || true
            ;;
        LABEL=*)
            blkid -L "${fstab_spec#LABEL=}" 2>/dev/null || true
            ;;
        /dev/*)
            echo "$fstab_spec"
            ;;
    esac
}

cleanup_storage_config() {
    local storage_device root_source root_disk storage_disk root_physical_disk storage_physical_disk

    storage_device="$(resolve_storage_device)"
    root_source="$(findmnt -n -o SOURCE / 2>/dev/null || true)"
    root_disk="$(lsblk -no PKNAME "$root_source" 2>/dev/null || true)"
    storage_disk="$(lsblk -no PKNAME "$storage_device" 2>/dev/null || true)"
    root_physical_disk="$root_disk"
    storage_physical_disk="$storage_disk"

    if [ -z "$root_physical_disk" ] && [ -n "$root_source" ]; then
        root_physical_disk="$(basename "$root_source")"
    fi

    if [ -z "$storage_physical_disk" ] && [ -n "$storage_device" ]; then
        storage_physical_disk="$(basename "$storage_device")"
    fi

    if [ -n "$storage_device" ] && [ -n "$root_source" ] && [ "$storage_device" = "$root_source" ]; then
        error "Refusing to reformat the root filesystem"
    fi

    if [ -n "$storage_device" ] && [ -n "$root_source" ] && [ "$root_physical_disk" = "$storage_physical_disk" ]; then
        error "Refusing to reformat storage on the same physical disk as the root filesystem"
    fi

    if [ -n "$storage_device" ]; then
        log "Unmounting configured storage: $NVME_MOUNT_POINT"
        umount "$NVME_MOUNT_POINT" >/dev/null 2>&1 || true
    fi

    if grep -q "$NVME_MOUNT_POINT" /etc/fstab 2>/dev/null; then
        log "Removing $NVME_MOUNT_POINT from /etc/fstab"
        sed -i "\\|$NVME_MOUNT_POINT|d" /etc/fstab
    fi

    if [ -f "$DOCKER_DAEMON_CONFIG" ] && grep -q "$NVME_MOUNT_POINT/docker" "$DOCKER_DAEMON_CONFIG" 2>/dev/null; then
        log "Removing ServicePi Docker daemon configuration"
        rm -f "$DOCKER_DAEMON_CONFIG"
    fi

    if [ -n "$storage_device" ]; then
        warning "Reformatting configured storage device: $storage_device"
        wipefs -a "$storage_device"
        mkfs.ext4 -F "$storage_device"
        e2label "$storage_device" "docker-storage"
        success "Configured storage device reformatted"
    else
        warning "No configured storage device could be identified for reformatting"
    fi
}

partial_uninstall() {
    log "Performing partial uninstall (data will be preserved)..."
    stop_containers false
    remove_update_services
    success "Partial uninstall complete"
    echo "ServicePi data and installation files were left intact in $INSTALL_DIR"
}

full_uninstall() {
    log "Performing full uninstall..."
    stop_containers true
    remove_containers_by_name
    remove_update_services
    cleanup_storage_config
    remove_installation
    remove_service_user
    success "Full uninstall complete"
}

print_help() {
    cat <<'EOF'
ServicePi Uninstall Script

Usage: sudo ./scripts/uninstall.sh [partial|full|--partial|--full|--dry-run]

Options:
  partial, --partial   Remove containers and update services, preserving data
  full, --full         Remove ServicePi, delete data, and reformat configured storage
  --dry-run            Show what would happen without making changes
  -h, --help           Show this help message

If no mode is provided, the script will prompt interactively.
EOF
}

main() {
    local mode=""
    local dry_run=false

    for arg in "$@"; do
        case "$arg" in
            partial|--partial)
                mode="partial"
                ;;
            full|--full)
                mode="full"
                ;;
            --dry-run)
                dry_run=true
                ;;
            -h|--help|help)
                print_help
                exit 0
                ;;
            *)
                error "Unknown option: $arg"
                ;;
        esac
    done

    if [ "$dry_run" = false ]; then
        check_root
    fi

    if [ -z "$mode" ]; then
        echo "Select uninstall mode:"
        echo "  1) Partial uninstall (preserve data)"
        echo "  2) Full uninstall (remove data and reformat storage)"
        read -r -p "Enter selection (1-2): " selection
        case "$selection" in
            1)
                mode="partial"
                ;;
            2)
                mode="full"
                ;;
            *)
                error "Invalid selection"
                ;;
        esac
    fi

    if [ "$dry_run" = true ]; then
        log "DRY RUN mode selected"
        if [ "$mode" = "partial" ]; then
            echo "Would stop ServicePi containers and remove update services while preserving data."
        else
            echo "Would stop ServicePi containers and volumes, remove data, remove update services, reformat configured storage, and remove the installation."
        fi
        exit 0
    fi

    echo ""
    if [ "$mode" = "partial" ]; then
        warning "This will remove ServicePi containers and update automation, but keep data intact."
        if ! confirm "Continue with partial uninstall"; then
            log "Partial uninstall cancelled"
            exit 0
        fi
        partial_uninstall
    else
        warning "This will permanently remove ServicePi, delete data, and reformat configured storage."
        if ! confirm "Continue with full uninstall"; then
            log "Full uninstall cancelled"
            exit 0
        fi
        full_uninstall
    fi
}

main "$@"

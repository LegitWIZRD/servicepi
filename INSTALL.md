# ServicePi Installation Guide

This guide provides detailed, security-focused installation instructions for ServicePi on your Raspberry Pi 5.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Security Considerations](#security-considerations)
- [Installation Methods](#installation-methods)
- [Post-Installation Setup](#post-installation-setup)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements

- **Raspberry Pi 5** (4GB or 8GB RAM recommended)
- **MicroSD card** (32GB or larger, Class 10 or better)
- **Network connection** (Ethernet recommended for initial setup)
- **Power supply** (Official Raspberry Pi 5 USB-C power supply recommended)
- **Optional**: NVMe SSD via PCIe HAT for improved storage performance

### Software Requirements

- **Raspberry Pi OS** (64-bit, Bookworm or later recommended)
- **Internet connection** for downloading packages and Docker images
- **SSH access** (if installing remotely)

### Knowledge Requirements

- Basic Linux command-line experience
- Understanding of Docker and containerization concepts
- Familiarity with text editors (nano, vim, etc.)

## Security Considerations

### Before You Begin

⚠️ **Important Security Notes:**

1. **Never run unverified scripts with root privileges** - Always inspect scripts before execution
2. **Default passwords must be changed** - Change all default credentials immediately after installation
3. **Network security** - Keep management interfaces behind a firewall or VPN
4. **Regular updates** - Keep your system and containers updated for security patches

### Network Security

ServicePi exposes several HTTP services on your local network:

- Port 80: Web dashboard
- Port 8080: IoT API
- Port 8053: Pi-hole Admin
- Port 9000: Portainer

**These services should ONLY be accessible on your trusted local network, not the internet.**

For remote access, use one of these methods:
- **VPN** (recommended): Set up WireGuard or Tailscale
- **SSH tunnel**: Forward ports through SSH
- **Reverse proxy with HTTPS**: Use Caddy or Nginx with Let's Encrypt

## Installation Methods

### Method 1: Secure Manual Installation (Recommended)

This is the recommended installation method as it allows you to inspect and verify the code before execution.

#### Step 1: Clone the Repository

```bash
# Create a temporary directory for verification
mkdir -p /tmp/servicepi-install
cd /tmp/servicepi-install

# Clone the repository
git clone https://github.com/LegitWIZRD/servicepi.git
cd servicepi
```

#### Step 2: Verify the Repository

```bash
# Check the latest commit
git log -1 --format="%H %s %an %ae"

# Optional: Verify the commit signature (if available)
git verify-commit HEAD

# Optional: Check the repository for any suspicious changes
git diff origin/main
```

#### Step 3: Inspect the Installation Script

**Always review scripts before running them with sudo!**

```bash
# View the installation script
less scripts/install.sh

# Or use your preferred editor
nano scripts/install.sh

# Check for any suspicious commands, especially:
# - Network requests (curl, wget)
# - File deletions (rm -rf)
# - User/permission changes
# - Service installations
```

#### Step 4: Run the Installation Script

Once you've verified the script is safe:

```bash
# Run the installation script
sudo ./scripts/install.sh
```

The installation script will:
1. Check for root privileges
2. Update system packages
3. Install Docker and Docker Compose
4. Create a dedicated `servicepi` user
5. Clone the repository to `/opt/servicepi`
6. Configure UFW firewall
7. Set up systemd services for automatic updates
8. Display next steps

#### Step 5: Configure Environment Variables

```bash
# Navigate to the installation directory
cd /opt/servicepi

# Copy the example environment file
sudo cp .env.example .env

# Edit the environment file with your settings
sudo nano .env
```

Important environment variables to configure:

```bash
# Project name (default: servicepi)
COMPOSE_PROJECT_NAME=servicepi

# Timezone (adjust for your location)
TZ=America/New_York

# Pi-hole password (CHANGE THIS!)
PIHOLE_PASSWORD=your-secure-password-here

# Your Raspberry Pi's IP address
PI_IP=192.168.1.100
```

#### Step 6: Review and Customize Docker Compose

```bash
# Review the services configuration
sudo nano /opt/servicepi/docker-compose.yml

# Key things to check:
# - Port mappings (ensure they don't conflict with existing services)
# - Volume mounts (ensure paths exist)
# - Environment variables
# - Privileged containers (GPIO access is commented by default)
```

#### Step 7: Start the Services

```bash
# Navigate to the installation directory
cd /opt/servicepi

# Start all services
sudo docker-compose up -d

# Check service status
sudo docker-compose ps

# View logs
sudo docker-compose logs -f
```

### Method 2: Quick Installation (Less Secure)

⚠️ **WARNING**: This method downloads and executes a script from the internet with root privileges. Only use this if you trust the source and have a secure network connection.

**This method is NOT recommended for production use.**

```bash
# Download the script first
curl -o /tmp/servicepi-install.sh https://raw.githubusercontent.com/LegitWIZRD/servicepi/main/scripts/install.sh

# Inspect the script
less /tmp/servicepi-install.sh

# If you trust the script, run it
sudo bash /tmp/servicepi-install.sh
```

## Post-Installation Setup

### 1. Change Default Passwords

#### Pi-hole

```bash
# Option 1: Set password via environment variable (already done if you edited .env)
# Option 2: Set password after installation
docker exec -it servicepi-pihole pihole -a -p
```

#### Portainer

1. Access Portainer at `http://your-pi-ip:9000`
2. Create an admin account on first access
3. Use a strong password (12+ characters, mixed case, numbers, symbols)

### 2. Configure Firewall Rules

The installation script automatically configures UFW. Verify the rules:

```bash
# Check UFW status
sudo ufw status verbose

# Expected rules:
# - Port 22/tcp (SSH)
# - Port 80/tcp (HTTP)
# - Port 8080/tcp (IoT API)
# - Port 8053/tcp (Pi-hole Admin)
# - Port 9000/tcp (Portainer)
# - Port 53 (DNS, if enabled)
```

To restrict access to specific networks:

```bash
# Example: Allow Portainer only from local network
sudo ufw delete allow 9000/tcp
sudo ufw allow from 192.168.1.0/24 to any port 9000 proto tcp

# Reload firewall
sudo ufw reload
```

### 3. Enable Automatic Updates (Optional)

```bash
# Enable the systemd timer for daily updates
sudo systemctl enable --now servicepi-update.timer

# Check timer status
sudo systemctl status servicepi-update.timer

# View timer schedule
sudo systemctl list-timers servicepi-update.timer
```

### 4. Configure NVMe Storage (Optional)

If you have an NVMe SSD connected via PCIe HAT:

```bash
# Review the NVMe setup script
less /opt/servicepi/scripts/setup-nvme-storage.sh

# Run the setup script (this will format the drive!)
sudo /opt/servicepi/scripts/setup-nvme-storage.sh

# The script will:
# 1. Detect available NVMe drives (excluding boot drive)
# 2. Show drive information
# 3. Ask for confirmation (you must type "FORMAT")
# 4. Format the selected drive
# 5. Mount the drive to /opt/docker-storage
# 6. Configure Docker to use NVMe storage

# After setup, restart Docker
sudo systemctl restart docker

# Restart services
cd /opt/servicepi
sudo docker-compose down
sudo docker-compose up -d
```

### 5. Enable Pi-hole DNS (Optional)

By default, Pi-hole DNS ports (53) are commented out to avoid conflicts. To enable network-wide DNS filtering:

```bash
# Edit docker-compose.yml
sudo nano /opt/servicepi/docker-compose.yml

# Uncomment the DNS ports in the pihole service section:
# ports:
#   - "53:53/tcp"
#   - "53:53/udp"

# Restart Pi-hole
cd /opt/servicepi
sudo docker-compose up -d pihole

# Configure your devices to use your Pi's IP as DNS server
# Example: Set DNS to 192.168.1.100 (your Pi's IP)
```

## Verification

### Check Service Health

```bash
# Check all containers are running
cd /opt/servicepi
sudo docker-compose ps

# Check web dashboard
curl http://localhost/health

# Check IoT API
curl http://localhost:8080/health

# Check Portainer
curl -I http://localhost:9000

# Check Pi-hole Admin
curl -I http://localhost:8053/admin
```

### Access Web Interfaces

From a computer on the same network:

- **Web Dashboard**: http://your-pi-ip/
- **Portainer**: http://your-pi-ip:9000/
- **IoT API**: http://your-pi-ip:8080/
- **Pi-hole Admin**: http://your-pi-ip:8053/admin

### View Logs

```bash
# All services
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs

# Specific service
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs web-backend
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs iot-service
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs portainer
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs pihole

# Follow logs in real-time
sudo docker-compose -f /opt/servicepi/docker-compose.yml logs -f
```

## Troubleshooting

### Services Not Starting

```bash
# Check Docker daemon
sudo systemctl status docker

# Check Docker logs
sudo journalctl -u docker -n 50

# Restart Docker
sudo systemctl restart docker

# Recreate containers
cd /opt/servicepi
sudo docker-compose down
sudo docker-compose up -d
```

### Port Conflicts

```bash
# Check which process is using a port
sudo netstat -tlnp | grep :80
sudo lsof -i :80

# Stop conflicting service (example: Apache)
sudo systemctl stop apache2
sudo systemctl disable apache2
```

### Permission Issues

```bash
# Fix ownership
sudo chown -R servicepi:servicepi /opt/servicepi

# Fix script permissions
sudo chmod +x /opt/servicepi/scripts/*.sh

# Fix Docker socket permissions
sudo usermod -aG docker servicepi
```

### Container Health Issues

```bash
# Check container logs
sudo docker logs servicepi-proxy
sudo docker logs servicepi-web-backend
sudo docker logs servicepi-iot
sudo docker logs servicepi-portainer
sudo docker logs servicepi-pihole

# Inspect container
sudo docker inspect servicepi-proxy

# Restart specific container
sudo docker restart servicepi-proxy
```

### Update Issues

```bash
# Check update log
sudo tail -f /var/log/servicepi-update.log

# Restore from backup
sudo ls -l /opt/servicepi-backups/

# Restore specific backup
sudo rm -rf /opt/servicepi
sudo cp -r /opt/servicepi-backups/servicepi-backup-YYYYMMDD-HHMMSS /opt/servicepi

# Restart services
cd /opt/servicepi
sudo docker-compose up -d
```

### NVMe Storage Issues

```bash
# Check mount
df -h | grep docker-storage

# Check fstab entry
grep docker-storage /etc/fstab

# Remount
sudo umount /opt/docker-storage
sudo mount /opt/docker-storage

# Check Docker data root
docker info | grep "Docker Root Dir"
```

## Uninstallation

If you need to uninstall ServicePi:

```bash
# Stop and remove containers
cd /opt/servicepi
sudo docker-compose down -v

# Remove installation directory
sudo rm -rf /opt/servicepi

# Remove service user
sudo userdel -r servicepi

# Remove systemd service
sudo systemctl disable --now servicepi-update.timer
sudo rm /etc/systemd/system/servicepi-update.service
sudo rm /etc/systemd/system/servicepi-update.timer
sudo systemctl daemon-reload

# Remove Docker (optional)
sudo apt-get remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo rm -rf /var/lib/docker

# Remove firewall rules (optional)
sudo ufw delete allow 80/tcp
sudo ufw delete allow 8080/tcp
sudo ufw delete allow 8053/tcp
sudo ufw delete allow 9000/tcp
sudo ufw delete allow 53/tcp
sudo ufw delete allow 53/udp
```

## Next Steps

After installation, you can:

1. **Customize the web dashboard**: Edit `/opt/servicepi/configs/web/index.html`
2. **Configure IoT service**: Edit `/opt/servicepi/configs/iot/config.ini`
3. **Add custom services**: Edit `/opt/servicepi/docker-compose.yml`
4. **Configure Pi-hole blocklists**: Edit `/opt/servicepi/configs/pihole/adlists.list`
5. **Set up VPN for remote access**: Consider WireGuard or Tailscale

## Additional Resources

- [ServicePi README](README.md)
- [Security Policy](SECURITY.md)
- [GitHub Repository](https://github.com/LegitWIZRD/servicepi)
- [Docker Documentation](https://docs.docker.com/)
- [Raspberry Pi Documentation](https://www.raspberrypi.com/documentation/)
- [Pi-hole Documentation](https://docs.pi-hole.net/)
- [Portainer Documentation](https://docs.portainer.io/)

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review the logs for error messages
3. Search existing [GitHub Issues](https://github.com/LegitWIZRD/servicepi/issues)
4. Open a new issue with:
   - Detailed description of the problem
   - Steps to reproduce
   - Log output
   - System information (OS version, Pi model, etc.)

## Contributing

Contributions are welcome! Please see the repository README for contribution guidelines.

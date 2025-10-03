# ServicePi 🍓

A Raspberry Pi 5 Docker container management system with automated CI/CD deployment pipeline.

## Overview

ServicePi provides a complete infrastructure-as-code solution for running Docker containers on a Raspberry Pi 5. The repository contains all configuration files, deployment scripts, and CI/CD pipelines needed to automatically deploy and manage services on your Pi.

## Features

- 🐳 **Docker Compose** orchestration for multiple services
- 🔄 **Automated CI/CD** pipeline with GitHub Actions
- 🛡️ **Security scanning** with Trivy vulnerability scanner
- 📊 **Web dashboard** for monitoring services
- 🔧 **Container management** with Portainer
- 🏠 **Home Assistant** for IoT automation and service orchestration
- 🚀 **One-command deployment** and updates
- 📝 **Configuration management** for all services
- 🔒 **Firewall configuration** and security hardening
- 🌐 **Reverse proxy** for service routing
- 🔗 **Inter-service communication** capabilities
- 💾 **NVMe storage setup** for optimal container performance

## Quick Start

### 1. Initial Setup on Raspberry Pi

Run the installation script on your Raspberry Pi 5:

```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/LegitWIZRD/servicepi/main/scripts/install.sh | sudo bash
```

Or manually:

```bash
# Clone the repository
sudo git clone https://github.com/LegitWIZRD/servicepi.git /opt/servicepi

# Run the installation script
sudo /opt/servicepi/scripts/install.sh
```

### 2. Access Your Services

After installation, access your services via HTTP:

- **Web Dashboard**: `http://your-pi-ip/` (HTTP :80)
- **Portainer**: `http://your-pi-ip:9000/` (HTTP :9000)
- **IoT API**: `http://your-pi-ip:8080/` (HTTP :8080)
- **Home Assistant**: `http://your-pi-ip:8123/` (HTTP :8123)
- **Health Check**: `http://your-pi-ip/health`

### 3. Configure Services

Edit the configuration files in `/opt/servicepi/configs/` to customize your services:

- `configs/nginx/default.conf` - Web server configuration
- `configs/web/index.html` - Dashboard content
- `configs/iot/config.ini` - IoT service settings
- `configs/homeassistant/configuration.yaml` - Home Assistant configuration (reverse proxy trusted networks)

## Repository Structure

```
servicepi/
├── .github/workflows/    # CI/CD pipeline configuration
│   └── ci-cd.yml        # GitHub Actions workflow
├── configs/             # Service configuration files
│   ├── nginx/          # Nginx web server config
│   ├── web/            # Web dashboard files
│   └── iot/            # IoT service configuration
├── scripts/            # Deployment and management scripts
│   ├── install.sh      # Initial installation script
│   └── update-pi.sh    # Update deployment script
├── docker-compose.yml  # Main service orchestration
├── .gitignore         # Git ignore rules
└── README.md          # This file
```

## Services Included

### Reverse Proxy (Nginx)
- Centralized routing for all services
- Security headers and CORS support
- CSRF token and cookie forwarding for Portainer and Home Assistant
- WebSocket support for real-time updates

### Web Dashboard
- Main dashboard
- Service status monitoring
- API access interface
- Health monitoring endpoints

### Container Management (Portainer)
- Web-based Docker management interface
- Monitor container status and logs
- Manage Docker images and volumes
- WebSocket support for real-time updates

### IoT API Service
- REST API for device management
- Sensor data collection and retrieval
- Inter-service communication capabilities
- GPIO access configuration for Pi hardware

### Home Assistant
- Open-source home automation platform
- Automate and control Portainer-hosted services
- IoT device integration and management
- User-friendly web interface for automation workflows
- Direct integration with IoT API service
- Configured to work behind reverse proxy with trusted networks

## CI/CD Pipeline

The GitHub Actions workflow automatically:

1. **Validates** configuration files and scripts
2. **Scans** for security vulnerabilities
3. **Tests** deployment in a clean environment
4. **Notifies** when updates are ready for deployment

### Automatic Updates

Enable automatic daily updates:

```bash
sudo systemctl enable --now servicepi-update.timer
```

### Manual Updates

Update your Pi services manually:

```bash
sudo /opt/servicepi/scripts/update-pi.sh
```

## Configuration

### Environment Variables

Create a `.env` file in the installation directory for environment-specific settings:

```bash
# Example .env file
COMPOSE_PROJECT_NAME=servicepi
TZ=America/New_York
```

### NVMe Storage Setup

ServicePi automatically detects and configures NVMe drives for optimal container storage performance. During installation, the setup script will:

- **Automatically detect** additional NVMe drives (excluding boot drive)
- **Safely format** the selected drive after user confirmation
- **Mount** the drive to `/opt/docker-storage`
- **Configure Docker** to use NVMe storage for all containers and volumes

#### Manual NVMe Setup

To manually configure NVMe storage after installation:

```bash
# Run the NVMe setup script
sudo /opt/servicepi/scripts/setup-nvme-storage.sh

# View help and options
sudo /opt/servicepi/scripts/setup-nvme-storage.sh help
```

#### Safety Features

- **Boot drive protection**: Automatically excludes the OS/boot drive
- **User confirmation**: Requires explicit confirmation before formatting
- **Drive information**: Shows detailed drive information before proceeding
- **Graceful fallback**: Works without NVMe drives using default storage

#### Benefits

- **Performance**: NVMe storage provides faster I/O for containers
- **Separation**: Application storage separated from OS for security
- **Capacity**: Utilize full capacity of additional NVMe drives
- **Reliability**: Reduces wear on the primary OS drive

### Custom Services

Add your own services by editing `docker-compose.yml`:

```yaml
your-service:
  image: your-image:latest
  container_name: servicepi-your-service
  volumes:
    - ./configs/your-service:/app/config
  networks:
    - servicepi-network
```

### GPIO Access

For services that need GPIO access, uncomment the privileged mode in `docker-compose.yml`:

```yaml
privileged: true
devices:
  - /dev/gpiomem:/dev/gpiomem
```

## Security

- **Firewall**: UFW configured to allow only necessary ports
- **User isolation**: Services run under dedicated user account
- **Vulnerability scanning**: Automated security scans in CI/CD
- **Regular updates**: Automatic system and container updates

## Monitoring

### Health Checks

- Web service: `http://your-pi-ip/health`
- Container status: `docker-compose ps`
- System logs: `journalctl -u servicepi-update`

### Logs

View service logs:

```bash
# All services
docker-compose -f /opt/servicepi/docker-compose.yml logs

# Specific service
docker-compose -f /opt/servicepi/docker-compose.yml logs web
```

## Troubleshooting

### Common Issues

1. **Services not starting**: Check Docker daemon status
   ```bash
   sudo systemctl status docker
   ```

2. **Port conflicts**: Ensure ports 80, 8080, 8123, and 9000 are available
   ```bash
   sudo netstat -tlnp | grep -E ':(80|8080|8123|9000) '
   ```

3. **Permission issues**: Verify ownership
   ```bash
   sudo chown -R servicepi:servicepi /opt/servicepi
   ```

4. **Portainer CSRF validation errors**: The proxy is configured to forward all necessary headers. If you still experience issues:
   ```bash
   # Check nginx proxy logs
   docker logs servicepi-proxy
   
   # Verify nginx configuration
   docker exec servicepi-proxy nginx -t
   
   # Test proxy header forwarding
   /opt/servicepi/scripts/test-proxy-headers.sh
   ```

5. **Home Assistant not accessible**: Ensure the service is running and healthy
   ```bash
   # Check Home Assistant status
   docker logs servicepi-homeassistant
   
   # Verify the service is responding
   curl -I http://localhost:8123
   ```

### Backup and Recovery

Create backup:
```bash
sudo /opt/servicepi/scripts/update-pi.sh --backup-only
```

Restore from backup:
```bash
sudo cp -r /opt/servicepi-backups/servicepi-backup-YYYYMMDD-HHMMSS/* /opt/servicepi/
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is open source. Feel free to use and modify as needed.

## Support

For issues and questions:
- Create an issue in this repository
- Check existing issues for solutions
- Review logs for error details

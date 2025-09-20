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
- 🚀 **One-command deployment** and updates
- 📝 **Configuration management** for all services
- 🔒 **Firewall configuration** and security hardening

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

After installation, access your services:

- **Web Dashboard**: `http://your-pi-ip/`
- **Portainer**: `http://your-pi-ip:9000`
- **Health Check**: `http://your-pi-ip/health`

### 3. Configure Services

Edit the configuration files in `/opt/servicepi/configs/` to customize your services:

- `configs/nginx/default.conf` - Web server configuration
- `configs/web/index.html` - Dashboard content
- `configs/iot/config.ini` - IoT service settings

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

### Web Server (Nginx)
- Serves the main dashboard
- Provides health check endpoint
- Can proxy API requests to other services

### Container Management (Portainer)
- Web-based Docker management interface
- Monitor container status and logs
- Manage Docker images and volumes

### IoT Service (Placeholder)
- Template for Pi-specific services
- GPIO access configuration
- Customizable for your specific needs

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

2. **Port conflicts**: Ensure ports 80 and 9000 are available
   ```bash
   sudo netstat -tlnp | grep -E ':(80|9000) '
   ```

3. **Permission issues**: Verify ownership
   ```bash
   sudo chown -R servicepi:servicepi /opt/servicepi
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

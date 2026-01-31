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
- 🚫 **Pi-hole DNS ad blocker** with curated blocklists
- 🔁 **N8N workflow automation** for integrations and automation
- 🤖 **OpenWebUI** for Large Language Model (LLM) interactions
- 📝 **WordPress** (optional) for user-friendly service directories
- 🔐 **Wazuh SIEM** (optional) for security monitoring and threat detection
- 🌐 **Domain name resolution** with .local domain support
- 🚀 **One-command deployment** and updates
- 📝 **Configuration management** for all services
- 🔒 **Firewall configuration** and security hardening
- 🌐 **Reverse proxy** with domain-based routing
- 🔗 **Inter-service communication** capabilities
- 💾 **NVMe storage setup** for optimal container performance

## Quick Start

### 1. Initial Setup on Raspberry Pi

⚠️ **Security Note**: For detailed security-focused installation instructions, see [INSTALL.md](INSTALL.md).

**Recommended Installation Method (Secure):**

```bash
# Clone the repository to a temporary location
git clone https://github.com/LegitWIZRD/servicepi.git /tmp/servicepi-install
cd /tmp/servicepi-install

# IMPORTANT: Review the installation script before running it
less scripts/install.sh

# Once verified, run the installation script
sudo ./scripts/install.sh
```

**After Installation:**

```bash
# Navigate to installation directory
cd /opt/servicepi

# Copy and configure environment variables
sudo cp .env.example .env
sudo nano .env

# IMPORTANT: Change default passwords in .env file
# Especially PIHOLE_PASSWORD - do NOT use the default 'servicepi' password!
```

For complete installation instructions with security best practices, see [INSTALL.md](INSTALL.md).

### 2. Access Your Services

After installation, access your services via HTTP using IP addresses or local domain names:

**Core Services:**
- **Web Dashboard**: `http://your-pi-ip/` or `http://servicepi.local/` (HTTP :80)
- **Portainer**: `http://your-pi-ip:9000/` or `http://portainer.local:9000/` (HTTP :9000)
- **IoT API**: `http://your-pi-ip:8080/` or `http://iot.local:8080/` (HTTP :8080)
- **Home Assistant**: `http://your-pi-ip:8123/` or `http://homeassistant.local:8123/` (HTTP :8123)
- **Pi-hole Admin**: `http://your-pi-ip:8053/admin` or `http://pihole.local:8053/admin` (HTTP :8053)
- **N8N Workflow Automation**: `http://your-pi-ip:5678/` or `http://n8n.local:5678/` (HTTP :5678)
- **OpenWebUI**: `http://your-pi-ip:3000/` or `http://openwebui.local:3000/` (HTTP :3000)
- **WordPress**: `http://your-pi-ip:8081/` or `http://wordpress.local:8081/` (HTTP :8081)
- **Health Check**: `http://your-pi-ip/health`

**Optional Services:**
- **Wazuh Dashboard**: `http://your-pi-ip:8443/` or `http://wazuh.local:8443/` (HTTP :8443) - See [Enabling Wazuh](#enabling-wazuh-optional) below

⚠️ **Security Warning**: These services are HTTP-only and should ONLY be accessible on your trusted local network. Do NOT expose them directly to the internet. For remote access, use a VPN (WireGuard, Tailscale) or SSH tunnel.

**Pi-hole DNS**: To enable network-wide ad blocking, uncomment the DNS ports in `docker-compose.yml` (lines 102-103) and point your devices to `your-pi-ip` as their DNS server.

**Local Domain Names**: To use `.local` domain names:
1. Edit `/opt/servicepi/configs/pihole/custom.list` and replace `<YOUR_PI_IP>` with your actual Pi IP address
2. Restart Pi-hole: `docker-compose -f /opt/servicepi/docker-compose.yml restart pihole`
3. Configure your devices to use your Pi as their DNS server (see Pi-hole section below)

### 3. Configure Services

Edit the configuration files in `/opt/servicepi/configs/` to customize your services:

- `configs/nginx/default.conf` - Web server configuration
- `configs/web/index.html` - Dashboard content
- `configs/iot/config.ini` - IoT service settings
- `configs/homeassistant/configuration.yaml` - Home Assistant configuration (reverse proxy trusted networks)
- `configs/pihole/adlists.list` - Pi-hole blocklists
- `configs/pihole/custom.list` - Custom DNS entries

## Repository Structure

```
servicepi/
├── .github/workflows/    # CI/CD pipeline configuration
│   └── ci-cd.yml        # GitHub Actions workflow
├── configs/             # Service configuration files
│   ├── nginx/          # Nginx web server config
│   ├── web/            # Web dashboard files
│   ├── iot/            # IoT service configuration
│   ├── homeassistant/  # Home Assistant configuration
│   └── pihole/         # Pi-hole blocklists and DNS config
├── scripts/            # Deployment and management scripts
│   ├── install.sh      # Initial installation script
│   └── update-pi.sh    # Update deployment script
├── docker-compose.yml  # Main service orchestration
├── .gitignore         # Git ignore rules
└── README.md          # This file
```

## Services Included

### Core Services

#### Reverse Proxy (Nginx)
- Centralized routing for all services
- Domain name resolution support (.local domains)
- Security headers and CORS support
- CSRF token and cookie forwarding for Portainer and Home Assistant
- WebSocket support for real-time updates

#### Web Dashboard
- Main dashboard
- Service status monitoring
- API access interface
- Health monitoring endpoints

#### Container Management (Portainer)
- Web-based Docker management interface
- Monitor container status and logs
- Manage Docker images and volumes
- WebSocket support for real-time updates

#### IoT API Service
- REST API for device management
- Sensor data collection and retrieval
- Inter-service communication capabilities
- GPIO access configuration for Pi hardware

#### Home Assistant
- Open-source home automation platform
- Automate and control Portainer-hosted services
- IoT device integration and management
- User-friendly web interface for automation workflows
- Direct integration with IoT API service
- Configured to work behind reverse proxy with trusted networks

#### Pi-hole DNS Ad Blocker
- Network-wide ad and tracker blocking
- DNS-level filtering for all devices
- Curated blocklists automatically applied
- Web-based admin interface for management
- Custom DNS entries support for .local domain resolution
- Query logging and statistics
- Blacklist/whitelist management

Access Pi-hole admin at `http://your-pi-ip:8053/admin` or `http://pihole.local:8053/admin`. To enable DNS blocking, uncomment port 53 mappings in `docker-compose.yml` and configure your devices to use your Pi's IP address as their DNS server.

#### N8N Workflow Automation
- Powerful workflow automation and integration platform
- Visual workflow editor with 400+ integrations
- Connect and automate services (APIs, databases, IoT devices)
- Schedule workflows and trigger on events
- Self-hosted alternative to Zapier/Make
- WebSocket support for real-time updates
- Integration with Home Assistant and IoT API service

Access N8N at `http://your-pi-ip:5678/` or `http://n8n.local:5678/`. Create workflows to automate tasks between your ServicePi services and external platforms.

#### OpenWebUI
- Modern web interface for Large Language Models (LLMs)
- Connects to Ollama for local LLM inference
- Chat interface similar to ChatGPT
- Support for multiple models and conversations
- File upload and document analysis capabilities
- Markdown rendering and code syntax highlighting
- Configurable backend URL for flexible deployment

**Configuration:**

OpenWebUI connects to an Ollama instance to provide LLM capabilities. You can configure the Ollama server location in your `.env` file:

```bash
# For Ollama running on the Pi host (default)
OLLAMA_BASE_URL=http://host.docker.internal:11434

# For Ollama running on another machine on your network
OLLAMA_BASE_URL=http://192.168.1.100:11434

# For Ollama running in another Docker container
OLLAMA_BASE_URL=http://ollama:11434
```

Access OpenWebUI at `http://your-pi-ip:3000/` or `http://openwebui.local:3000/`. 

**Prerequisites:** OpenWebUI requires an Ollama instance to be running. Install Ollama on your Pi or another server before using OpenWebUI. Visit [https://ollama.ai](https://ollama.ai) for installation instructions.

### Optional Services

### WordPress
- User-friendly dashboard for creating service directories
- Content management system (CMS) for custom pages
- Easy-to-use interface for non-technical users
- MySQL database backend for content storage
- Extensive theme and plugin ecosystem

**WordPress is enabled by default** in ServicePi and ready to use at `http://your-pi-ip:8081/` or `http://wordpress.local:8081/`.

**Configuration:**

1. **Update passwords in `.env` file** (IMPORTANT - change from defaults!):
   ```bash
   sudo nano /opt/servicepi/.env
   # Change: WORDPRESS_DB_PASSWORD, WORDPRESS_DB_ROOT_PASSWORD
   ```

2. **Complete WordPress setup:** Access at `http://your-pi-ip:8081/` and follow the installation wizard.

3. **Create your dashboard:** Use WordPress to build a custom landing page with service links and documentation.

**Use Case:** Create a simple landing page with links to all your ServicePi services, making it easy for family members or team members to find and access services.

### Wazuh Security Monitoring (Optional)
- Security information and event management (SIEM)
- Threat detection and incident response
- Log data analysis and file integrity monitoring
- Vulnerability detection and compliance management
- Agent-based monitoring for endpoints

⚠️ **Resource Requirements**: Wazuh requires significant resources - **minimum 4GB RAM, 8GB recommended**. Only enable on Pi 5 with sufficient RAM.

**Enabling Wazuh:**

1. **Set environment flag in `.env` file**:
   ```bash
   sudo nano /opt/servicepi/.env
   # Set: ENABLE_WAZUH=true
   # Change all Wazuh passwords from defaults!
   ```

2. **Uncomment Wazuh services** in `docker-compose.yml`:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   # Uncomment: wazuh-manager, wazuh-indexer, wazuh-dashboard services
   # Uncomment: all wazuh_* volumes
   # Uncomment: wazuh-dashboard in nginx-proxy depends_on
   # Uncomment: port 8443:8443 in nginx-proxy ports
   ```

3. **Uncomment Wazuh nginx configuration**:
   ```bash
   sudo nano /opt/servicepi/configs/nginx/proxy/default.conf
   # Uncomment the Wazuh Dashboard server block
   ```

4. **Configure firewall**:
   ```bash
   sudo ufw allow 8443/tcp
   # Optional for agents:
   # sudo ufw allow 1514/tcp
   # sudo ufw allow 1515/tcp
   ```

5. **Start services in order** (important!):
   ```bash
   cd /opt/servicepi
   sudo docker compose up -d wazuh-indexer
   sleep 60  # Wait for indexer to start
   sudo docker compose up -d wazuh-manager
   sleep 30  # Wait for manager to start
   sudo docker compose up -d wazuh-dashboard
   ```

6. **Access Wazuh:** `http://your-pi-ip:8443/` or `http://wazuh.local:8443/` and log in with credentials from `.env`.

For detailed setup instructions, see [docs/OPTIONAL_SERVICES.md](docs/OPTIONAL_SERVICES.md).

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

### Automated Container Version Updates

ServicePi includes automated systems to keep your containers up to date:

#### 1. Automated Version Checking (Recommended)

A GitHub Actions workflow runs **weekly on Mondays at 09:00 UTC** to check for new container versions:

- **Checks** Docker Hub and GitHub Container Registry for latest LTS versions
- **Creates issues** automatically when updates are available
- **Assigns to Copilot** for automated PR creation
- **Prevents duplicate issues** by updating existing open issues

The workflow checks these containers:
- Portainer
- n8n
- Pi-hole
- Home Assistant

You can also trigger the check manually from the Actions tab in your GitHub repository.

#### 2. Dependabot Integration

Dependabot is enabled to automatically:
- Monitor Docker images in `docker-compose.yml`
- Monitor Python dependencies in IoT service
- Monitor GitHub Actions versions
- Create pull requests for updates weekly

Configure Dependabot settings in `.github/dependabot.yml`.

### Manual Container Updates

Docker images are pinned to specific versions for reproducibility and security. To update to newer versions manually:

1. **Review the latest versions**:
   - Nginx: Check [Docker Hub - nginx](https://hub.docker.com/_/nginx/tags?page=1&name=alpine)
   - Portainer: Check [Docker Hub - portainer-ce](https://hub.docker.com/r/portainer/portainer-ce/tags)
   - Home Assistant: Check [GitHub - home-assistant releases](https://github.com/home-assistant/core/releases)
   - Pi-hole: Check [Docker Hub - pihole](https://hub.docker.com/r/pihole/pihole/tags)
   - n8n: Check [Docker Hub - n8n](https://hub.docker.com/r/n8nio/n8n/tags)

2. **Update docker-compose.yml**:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   # Update image tags to new versions
   ```

3. **Pull new images and restart**:
   ```bash
   cd /opt/servicepi
   sudo docker-compose pull
   sudo docker-compose up -d
   ```

4. **Verify services are running**:
   ```bash
   sudo docker-compose ps
   ```

**Recommendation**: The automated systems handle most updates, but always review changes before merging. Test updates in a non-production environment first if possible.

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

⚠️ **Security Note**: GPIO access requires privileged container mode, which increases security risk.

For services that need GPIO access, uncomment the privileged mode in `docker-compose.yml`:

```yaml
privileged: true
devices:
  - /dev/gpiomem:/dev/gpiomem
```

**Only enable privileged mode if absolutely necessary for your use case.**

## Security

For comprehensive security information, see [SECURITY.md](SECURITY.md).

### Security Features

- **Firewall**: UFW configured to allow only necessary ports (SSH, HTTP services, DNS)
- **User isolation**: Services run under dedicated `servicepi` user account
- **Vulnerability scanning**: Automated security scans in CI/CD pipeline
- **Regular updates**: Automatic system and container updates
- **Network filtering**: Pi-hole provides DNS-level ad and malware blocking
- **Secret management**: `.env` files are git-ignored by default
- **Container isolation**: Services communicate through internal Docker network
- **Minimal privileges**: Containers run with minimal required permissions

### Important Security Recommendations

⚠️ **Change Default Passwords**: After installation, immediately change:
- Pi-hole web interface password (in `.env` file)
- Portainer admin password (on first access)
- Home Assistant admin password (on first access)

⚠️ **Network Security**: 
- Keep management interfaces accessible only on your local network
- Use a VPN (WireGuard, Tailscale) for remote access
- Do NOT expose HTTP services directly to the internet
- Consider adding HTTPS via a reverse proxy for production use

⚠️ **Container Privileges**:
- Pi-hole requires `CAP_NET_ADMIN` for DNS functionality (necessary, cannot be removed)
- GPIO access (commented by default) requires `privileged: true` - only enable if needed
- Review any privileged containers before enabling

For detailed security guidelines, vulnerability reporting, and best practices, see [SECURITY.md](SECURITY.md).

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

2. **Port conflicts**: Ensure ports 53, 80, 5678, 8053, 8080, 8081, 8123, 8443, and 9000 are available
   ```bash
   sudo netstat -tlnp | grep -E ':(53|80|5678|8053|8080|8081|8123|8443|9000) '
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

6. **Pi-hole DNS not working**: Check that Pi-hole is running and DNS ports are enabled
   ```bash
   # Check Pi-hole status
   docker logs servicepi-pihole
   
   # Verify DNS ports are uncommented in docker-compose.yml
   grep -A 3 "pihole:" /opt/servicepi/docker-compose.yml | grep "53:53"
   
   # If ports are commented, edit docker-compose.yml to uncomment them
   sudo nano /opt/servicepi/docker-compose.yml
   
   # Restart Pi-hole after enabling ports
   docker-compose -f /opt/servicepi/docker-compose.yml up -d pihole
   
   # Test DNS resolution (only works if ports are enabled)
   dig @localhost example.com
   
   # Verify Pi-hole admin is accessible
   curl -I http://localhost:8053/admin
   
   # Update Pi-hole gravity (blocklists)
   docker exec servicepi-pihole pihole -g
   ```

7. **N8N secure cookie error**: If you see "Your n8n server is configured to use a secure cookie" error, ensure the N8N_SECURE_COOKIE environment variable is properly configured:
   ```bash
   # Verify N8N configuration
   /opt/servicepi/scripts/test-n8n-config.sh
   
   # Check N8N logs
   docker logs servicepi-n8n
   
   # Restart N8N service
   docker-compose -f /opt/servicepi/docker-compose.yml restart n8n
   
   # Access N8N via HTTP
   curl -I http://localhost:5678
   ```
   See [docs/N8N_SECURE_COOKIE_FIX.md](docs/N8N_SECURE_COOKIE_FIX.md) for more details.

8. **WordPress database connection errors**: Ensure the WordPress database is running and credentials match
   ```bash
   # Check WordPress and database status
   docker logs servicepi-wordpress
   docker logs servicepi-wordpress-db
   
   # Verify database connection
   docker exec servicepi-wordpress-db mysql -u wordpress -p -e "SHOW DATABASES;"
   
   # Restart WordPress services
   docker-compose -f /opt/servicepi/docker-compose.yml restart wordpress wordpress-db
   
   # Access WordPress setup
   curl -I http://localhost:8081
   ```

9. **Wazuh services not starting**: Wazuh requires significant resources and proper configuration
   ```bash
   # Check Wazuh logs
   docker logs servicepi-wazuh-manager
   docker logs servicepi-wazuh-indexer
   docker logs servicepi-wazuh-dashboard
   
   # Verify memory availability (Wazuh needs 4GB+ RAM)
   free -h
   
   # Check indexer status
   curl -k -u admin:SecretPassword https://localhost:9200
   
   # Restart Wazuh services (order matters)
   docker-compose -f /opt/servicepi/docker-compose.yml restart wazuh-indexer
   sleep 30
   docker-compose -f /opt/servicepi/docker-compose.yml restart wazuh-manager
   sleep 20
   docker-compose -f /opt/servicepi/docker-compose.yml restart wazuh-dashboard
   ```

10. **Local domain names not resolving**: Ensure Pi-hole custom.list is configured and DNS is set
    ```bash
    # Edit Pi-hole custom DNS entries
    sudo nano /opt/servicepi/configs/pihole/custom.list
    # Replace <YOUR_PI_IP> with your actual Pi IP address
    
    # Restart Pi-hole to apply changes
    docker-compose -f /opt/servicepi/docker-compose.yml restart pihole
    
    # Verify DNS resolution (requires Pi-hole DNS enabled)
    dig @localhost servicepi.local
    dig @localhost wordpress.local
    
    # Check your device's DNS settings - should point to Pi IP
    # Alternatively, edit /etc/hosts on your device:
    # <PI_IP> servicepi.local wordpress.local wazuh.local
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

Contributions are welcome! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature`)
3. Make your changes following the coding standards
4. Test thoroughly (run shellcheck, validate docker-compose)
5. Commit your changes with descriptive messages
6. Submit a pull request

### Development Tools

- **Pre-commit hooks**: See `.pre-commit-config.yaml.example` for code quality checks
- **Dependabot**: See `.github/dependabot.yml.example` for automated dependency updates
- **Shellcheck**: Validate shell scripts before committing
- **Docker Compose validation**: Run `docker-compose config` to validate syntax

For more information, see:
- [Security Policy](SECURITY.md) - Vulnerability reporting and security guidelines
- [Installation Guide](INSTALL.md) - Detailed installation instructions
- [Dependency Management](docs/DEPENDENCY_MANAGEMENT.md) - How to update dependencies
- [Optional Services Guide](docs/OPTIONAL_SERVICES.md) - WordPress and Wazuh setup
- [Domain Name Resolution](docs/DOMAIN_NAME_RESOLUTION.md) - Configure .local domains

## Additional Documentation

- **[SECURITY.md](SECURITY.md)** - Security policy, vulnerability reporting, and best practices
- **[INSTALL.md](INSTALL.md)** - Detailed installation guide with security focus
- **[docs/DEPENDENCY_MANAGEMENT.md](docs/DEPENDENCY_MANAGEMENT.md)** - Managing and updating dependencies
- **[docs/PIHOLE_INTEGRATION.md](docs/PIHOLE_INTEGRATION.md)** - Pi-hole setup and configuration
- **[docs/CSRF_PROXY_FIX.md](docs/CSRF_PROXY_FIX.md)** - Portainer CSRF configuration
- **[docs/N8N_SECURE_COOKIE_FIX.md](docs/N8N_SECURE_COOKIE_FIX.md)** - N8N HTTP-only configuration
- **[docs/OPTIONAL_SERVICES.md](docs/OPTIONAL_SERVICES.md)** - WordPress and Wazuh setup guide
- **[docs/DOMAIN_NAME_RESOLUTION.md](docs/DOMAIN_NAME_RESOLUTION.md)** - Configure .local domain names

## License

This project is open source. Feel free to use and modify as needed.

## Support

For issues and questions:
- Create an issue in this repository
- Check existing issues for solutions
- Review logs for error details

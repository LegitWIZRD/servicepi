# Copilot Instructions for ServicePi

## Project Overview

ServicePi is a Raspberry Pi 5 Docker container management system with automated CI/CD deployment pipeline. It provides a complete infrastructure-as-code solution for running Docker containers on a Raspberry Pi 5.

## Architecture

- **Deployment Target**: Raspberry Pi 5 (ARM64 architecture)
- **Container Orchestration**: Docker Compose
- **Reverse Proxy**: Nginx with SSL/TLS termination
- **Services**:
  - Web dashboard (HTML/CSS/JavaScript)
  - Portainer (container management UI)
  - IoT API service (Python Flask)
- **CI/CD**: GitHub Actions with security scanning (Trivy)
- **Storage**: Optional NVMe storage configuration

## Technology Stack

- **Shell Scripts**: Bash (deployment, installation, updates)
- **Python**: Flask 2.3.3 for IoT API service
- **Web**: HTML, CSS, JavaScript for dashboard
- **Infrastructure**: Docker, Docker Compose, Nginx
- **Security**: SSL/TLS certificates, UFW firewall

## Coding Standards

### Shell Scripts
- Use `set -e` for error handling
- Include descriptive comments and logging
- Use color-coded output (RED, GREEN, YELLOW, NC)
- Validate prerequisites (root access, dependencies)
- Create backups before making changes
- Follow existing patterns in `scripts/install.sh` and `scripts/update-pi.sh`

### Python (Flask API)
- Use Python 3 with type hints where appropriate
- Follow Flask best practices for REST API design
- Configure CSRF protection appropriately for API endpoints
- Use CORS for cross-origin requests
- Load configuration from environment variables or config files
- Return proper HTTP status codes and JSON responses

### Docker & Infrastructure
- Use Alpine images where possible for smaller footprint
- Configure restart policies (`unless-stopped`)
- Use internal networks for service-to-service communication
- Expose only necessary ports
- Use SSL/TLS for all external services
- Follow ARM64 compatibility requirements for Raspberry Pi

### Configuration Files
- Store sensitive data in environment variables (`.env` files)
- Keep SSL certificates in `configs/nginx/ssl/`
- Organize configs by service in `configs/` directory
- Use self-signed certificates for development, proper certificates for production

## Repository Structure

```
servicepi/
├── .github/workflows/    # CI/CD pipeline configuration
├── configs/             # Service configuration files
│   ├── nginx/          # Nginx proxy and SSL config
│   ├── web/            # Web dashboard files
│   └── iot/            # IoT service (Python Flask app)
├── scripts/            # Deployment and management scripts
│   ├── install.sh      # Initial installation script
│   └── update-pi.sh    # Update deployment script
├── services/           # Docker service configurations
└── docker-compose.yml  # Main service orchestration
```

## Development Guidelines

### Making Changes

1. **Always validate** shell scripts with `shellcheck` before committing
2. **Test Docker Compose** changes with `docker-compose config`
3. **Ensure ARM64 compatibility** for Raspberry Pi deployment
4. **Update documentation** when changing configuration or adding features
5. **Maintain backwards compatibility** for existing installations

### Security Considerations

- Never commit secrets or certificates to the repository
- Use environment variables for sensitive configuration
- Ensure all external services use HTTPS/SSL
- Configure UFW firewall rules appropriately
- Scan for vulnerabilities with Trivy in CI/CD
- Follow principle of least privilege for services

### Deployment Process

1. Changes pushed to `main` trigger CI/CD pipeline
2. Configuration validation runs (docker-compose, shellcheck)
3. Security scanning with Trivy
4. Optional automated deployment to Raspberry Pi via SSH
5. Services are updated with zero-downtime where possible

### File Paths and Conventions

- **Installation directory**: `/opt/servicepi`
- **Log files**: `/var/log/servicepi-*.log`
- **Backup directory**: `/opt/servicepi-backups`
- **Service user**: `servicepi`
- **Exposed ports**:
  - 80 (HTTP redirects to HTTPS)
  - 443 (Web dashboard HTTPS)
  - 9443 (Portainer HTTPS)
  - 8443 (IoT API HTTPS)

## Common Tasks

### Adding a New Service

1. Add service definition to `docker-compose.yml`
2. Create config directory in `configs/`
3. Configure SSL certificate in `configs/nginx/ssl/`
4. Add Nginx proxy configuration
5. Update firewall rules in `scripts/install.sh` if needed
6. Document the service in README.md

### Updating Dependencies

- Python: Update `configs/iot/requirements.txt`
- Docker images: Update version tags in `docker-compose.yml`
- Always test on ARM64 architecture

### Testing Changes

1. Validate locally with Docker Compose
2. Test shell scripts with shellcheck
3. Verify SSL certificates are generated correctly
4. Check service connectivity through Nginx proxy
5. Review CI/CD pipeline execution

## Important Notes

- This system is designed for **Raspberry Pi 5** - ensure ARM64 compatibility
- All services communicate through an internal Docker network
- SSL certificates are self-signed by default (use proper certs in production)
- The update script (`update-pi.sh`) creates backups before making changes
- Services are configured for automatic restart unless stopped manually

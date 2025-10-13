# Dependency Management

This document describes how to manage and update dependencies in the ServicePi project.

## Docker Images

ServicePi uses Docker images from trusted sources. All images are pinned to specific versions for security and reproducibility.

### Current Image Versions

| Service | Image | Version | Notes |
|---------|-------|---------|-------|
| Nginx Proxy | nginx:alpine | 1.27.3-alpine | Reverse proxy for all services |
| Web Backend | nginx:alpine | 1.27.3-alpine | Static content server |
| Portainer | portainer/portainer-ce | 2.33.2-alpine | Container management UI |
| Home Assistant | ghcr.io/home-assistant/home-assistant | 2025.10.2 | Home automation platform |
| Pi-hole | pihole/pihole | 2025.08.0 | DNS ad blocker |
| N8N | n8nio/n8n | 1.114.3 | Workflow automation platform |
| IoT Service | (custom build) | Python 3.13-alpine | Built from local Dockerfile |

### Why Pin Versions?

1. **Security**: Know exactly what code is running in your containers
2. **Reproducibility**: Same deployment produces same results
3. **Stability**: Avoid unexpected breaking changes from automatic updates
4. **Testing**: Test updates before applying them to production

### Updating Images

#### 1. Check for Updates

Regularly check for new versions:

- **Nginx**: https://hub.docker.com/_/nginx/tags?page=1&name=alpine
- **Portainer**: https://hub.docker.com/r/portainer/portainer-ce/tags
- **Home Assistant**: https://github.com/home-assistant/core/releases
- **Pi-hole**: https://hub.docker.com/r/pihole/pihole/tags

#### 2. Review Release Notes

Always review release notes before updating:

- Check for breaking changes
- Review new features
- Look for security fixes
- Verify ARM64/aarch64 compatibility

#### 3. Update docker-compose.yml

Edit the image tag in `docker-compose.yml`:

```yaml
# Before
image: nginx:1.27.3-alpine

# After
image: nginx:1.27.4-alpine
```

#### 4. Test Locally (if possible)

```bash
cd /opt/servicepi

# Pull new images
sudo docker-compose pull

# Stop and remove old containers
sudo docker-compose down

# Start with new images
sudo docker-compose up -d

# Check logs
sudo docker-compose logs -f

# Verify services are working
curl http://localhost/health
curl http://localhost:8080/health
```

#### 5. Commit Changes

```bash
git add docker-compose.yml
git commit -m "Update nginx to 1.27.4-alpine"
git push
```

### Update Schedule Recommendations

- **Security Updates**: Apply as soon as possible after testing
- **Minor Updates**: Monthly review and update cycle
- **Major Updates**: Plan carefully, may require configuration changes

### Automated Dependency Updates (Dependabot)

GitHub's Dependabot can automatically create pull requests for dependency updates.

#### Enabling Dependabot

Create `.github/dependabot.yml`:

```yaml
version: 2
updates:
  # Docker images in docker-compose.yml
  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "LegitWIZRD"
    labels:
      - "dependencies"
      - "docker"
    
  # Python dependencies for IoT service
  - package-ecosystem: "pip"
    directory: "/configs/iot"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "LegitWIZRD"
    labels:
      - "dependencies"
      - "python"
    
  # GitHub Actions workflows
  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"
    open-pull-requests-limit: 5
    reviewers:
      - "LegitWIZRD"
    labels:
      - "dependencies"
      - "ci-cd"
```

#### Dependabot Workflow

1. Dependabot creates a PR for each dependency update
2. CI/CD pipeline runs automatically on the PR
3. Review the PR and release notes
4. Approve and merge if tests pass
5. Deploy the update to your Raspberry Pi

## Python Dependencies (IoT Service)

The IoT service uses Python with Flask. Dependencies are managed in `configs/iot/requirements.txt`.

### Current Dependencies

```
Flask==3.1.1
Werkzeug==3.1.3
flask-wtf==1.2.2
flask-cors==5.0.0
configparser==7.2.0
requests==2.32.3
```

### Updating Python Dependencies

#### 1. Check for Updates

```bash
pip list --outdated
```

#### 2. Update requirements.txt

Update version numbers in `configs/iot/requirements.txt`:

```
Flask==3.1.1
Werkzeug==3.1.3
flask-wtf==1.2.2
flask-cors==5.0.0
configparser==7.2.0
requests==2.32.3
```

#### 3. Rebuild the IoT Service

```bash
cd /opt/servicepi
sudo docker-compose build iot-service
sudo docker-compose up -d iot-service
```

#### 4. Test the Service

```bash
curl http://localhost:8080/health
curl http://localhost:8080/api/sensors
```

### Security Scanning

Use `pip-audit` to check for known vulnerabilities:

```bash
# Install pip-audit
pip install pip-audit

# Scan requirements.txt
pip-audit -r configs/iot/requirements.txt
```

## System Dependencies

The Raspberry Pi OS and system packages should also be kept updated.

### Update System Packages

```bash
# Update package list
sudo apt-get update

# Upgrade packages
sudo apt-get upgrade -y

# Clean up
sudo apt-get autoremove -y
sudo apt-get autoclean
```

### Update Docker and Docker Compose

Docker and Docker Compose are installed during the initial setup. To update:

```bash
# Update Docker
sudo apt-get update
sudo apt-get install --only-upgrade docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Verify versions
docker --version
docker compose version
```

## Security Vulnerability Scanning

### Trivy Scanning

ServicePi uses Trivy for vulnerability scanning in the CI/CD pipeline. You can also run Trivy locally:

```bash
# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan the repository
cd /opt/servicepi
trivy fs .

# Scan specific Docker images
trivy image nginx:1.27.3-alpine
trivy image portainer/portainer-ce:2.33.2-alpine
trivy image ghcr.io/home-assistant/home-assistant:2025.10.2
trivy image pihole/pihole:2025.08.0
trivy image n8nio/n8n:1.114.3

# Scan with severity filtering
trivy image --severity HIGH,CRITICAL nginx:1.27.3-alpine
```

### GitHub Security Alerts

Enable GitHub security alerts for automatic vulnerability notifications:

1. Go to repository Settings
2. Navigate to Security & analysis
3. Enable "Dependabot alerts"
4. Enable "Dependabot security updates"

## Version Control Best Practices

### Semantic Versioning

When tagging releases, use semantic versioning (MAJOR.MINOR.PATCH):

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Git Tags

Tag stable releases:

```bash
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Changelog

Maintain a CHANGELOG.md to track changes:

```markdown
# Changelog

## [1.1.0] - 2024-10-12
### Added
- Security documentation (SECURITY.md, INSTALL.md)
- .env.example template
- CI check for unpinned Docker images

### Changed
- Pinned all Docker images to specific versions
- Removed insecure curl|bash installation method
- Enhanced NVMe setup script with --dry-run option

### Security
- Fixed vulnerability in Flask (CVE-XXXX-XXXXX)
```

## Rollback Procedure

If an update causes issues, rollback to the previous version:

### Docker Images

```bash
cd /opt/servicepi

# Revert docker-compose.yml
git checkout HEAD~1 docker-compose.yml

# Pull old images
sudo docker-compose pull

# Restart services
sudo docker-compose up -d
```

### Full System Rollback

```bash
# List backups
ls -l /opt/servicepi-backups/

# Restore from backup
sudo systemctl stop docker
sudo rm -rf /opt/servicepi
sudo cp -r /opt/servicepi-backups/servicepi-backup-YYYYMMDD-HHMMSS /opt/servicepi
sudo systemctl start docker
cd /opt/servicepi
sudo docker-compose up -d
```

## Resources

- [Docker Hub](https://hub.docker.com/)
- [GitHub Container Registry](https://ghcr.io/)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [Dependabot Documentation](https://docs.github.com/en/code-security/dependabot)
- [OWASP Dependency Check](https://owasp.org/www-project-dependency-check/)
- [pip-audit](https://github.com/pypa/pip-audit)

## Getting Help

If you encounter issues with dependency updates:

1. Check the [Troubleshooting](README.md#troubleshooting) section
2. Review service logs: `sudo docker-compose logs [service-name]`
3. Consult the upstream project's documentation
4. Open an issue on the ServicePi GitHub repository

# Security Policy

## Supported Versions

ServicePi is currently in active development. Security updates are provided for the latest version on the `main` branch.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

We take the security of ServicePi seriously. If you discover a security vulnerability, please follow these steps:

### 1. **Do Not** Open a Public Issue

Please do not report security vulnerabilities through public GitHub issues, discussions, or pull requests.

### 2. Report Privately

Send a detailed report to the repository maintainers via GitHub's private vulnerability reporting feature:

1. Go to the [Security tab](https://github.com/LegitWIZRD/servicepi/security)
2. Click "Report a vulnerability"
3. Fill out the vulnerability report form

Alternatively, you can open a private discussion or contact the maintainer directly.

### 3. What to Include

Please include as much of the following information as possible:

- Type of vulnerability (e.g., remote code execution, privilege escalation, information disclosure)
- Full paths of source file(s) related to the vulnerability
- Location of the affected source code (tag/branch/commit or direct URL)
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if available)
- Impact of the vulnerability and potential attack scenarios
- Any suggested fixes or mitigations

### 4. Response Timeline

- **Initial Response**: We aim to acknowledge your report within 48 hours
- **Status Updates**: We will provide regular updates on our progress every 5-7 days
- **Resolution**: We aim to release a fix within 30 days for critical vulnerabilities
- **Disclosure**: We follow a coordinated disclosure process and will work with you on the disclosure timeline

### 5. Recognition

We appreciate the security research community's efforts. With your permission, we will:

- Acknowledge your contribution in the security advisory
- Credit you in the release notes (unless you prefer to remain anonymous)

## Security Best Practices for Users

### Installation Security

**❌ DO NOT use the `curl | sudo bash` pattern:**

```bash
# DON'T DO THIS - unverified remote execution
curl -sSL https://raw.githubusercontent.com/LegitWIZRD/servicepi/main/scripts/install.sh | sudo bash
```

**✅ DO use verified local installation:**

```bash
# Clone the repository
git clone https://github.com/LegitWIZRD/servicepi.git /tmp/servicepi-verify

# Inspect the installation script
less /tmp/servicepi-verify/scripts/install.sh

# Verify the repository commit (optional but recommended)
cd /tmp/servicepi-verify
git log -1 --format="%H %s"

# Run the installation script locally
sudo /tmp/servicepi-verify/scripts/install.sh
```

### Secret Management

- **Never commit secrets** to the repository
- Use a `.env` file for sensitive configuration (already in `.gitignore`)
- For production deployments, consider using Docker Secrets or a secrets manager
- Rotate credentials regularly, especially default passwords

### Container Security

- **Privileged Containers**: ServicePi minimizes privileged container usage
  - Pi-hole requires `NET_ADMIN` capability for DNS functionality
  - GPIO access (commented by default) requires privileged mode
- Review the `docker-compose.yml` file before deploying to understand container permissions

### Network Security

- **Firewall Configuration**: The installation script configures UFW to restrict access
- **Management Interfaces**: Keep Portainer, Home Assistant, and Pi-hole behind a firewall or VPN
- **Port Exposure**: Only expose ports 80, 8080, 8123, 8053, 9000 to your local network, not the internet
- Consider using a VPN (e.g., WireGuard, Tailscale) for remote access

### Drive Formatting Safety

The NVMe storage setup script (`setup-nvme-storage.sh`) includes multiple safety features:

- Automatically excludes the boot/root drive
- Displays drive information before formatting
- Requires explicit user confirmation (typing "FORMAT")
- Supports `--dry-run` mode to preview actions

Always verify the drive path before formatting.

### Update Security

- **Automatic Updates**: The systemd timer enables automatic security updates
- **Manual Updates**: Review changes before updating with `git log` or `git diff`
- **Backups**: The update script automatically creates backups before applying changes

## Security Features

ServicePi includes the following security features:

### Built-in Security

- ✅ **Vulnerability Scanning**: Automated Trivy scanning in CI/CD pipeline
- ✅ **Shell Script Validation**: Automated shellcheck validation
- ✅ **Firewall Configuration**: UFW configured during installation
- ✅ **User Isolation**: Services run under dedicated `servicepi` user
- ✅ **Network Filtering**: Pi-hole provides DNS-level ad and malware blocking
- ✅ **Secret Protection**: `.env` files are git-ignored by default
- ✅ **Update Backups**: Automatic backup creation before updates

### Container Security

- Internal Docker network for service-to-service communication
- Minimal container privileges (except where required for functionality)
- Restart policies prevent service interruptions
- Resource limits can be configured in `docker-compose.yml`

### CI/CD Security

- Configuration validation before deployment
- Security scanning of all dependencies
- Manual deployment trigger (no automatic remote deployments)
- Signed commits recommended for deployment workflows

## Known Security Considerations

### Default Credentials

Several services have default credentials that **must** be changed on first use:

- **Pi-hole**: Default password is `servicepi` (set via `PIHOLE_PASSWORD` environment variable)
- **Portainer**: Set up on first access
- **Home Assistant**: Set up on first access

### Port Exposure

By default, the following ports are exposed on the host:

- Port 80: Web dashboard (HTTP)
- Port 8080: IoT API (HTTP)
- Port 8123: Home Assistant (HTTP)
- Port 8053: Pi-hole Admin (HTTP)
- Port 9000: Portainer (HTTP)
- Port 53 (TCP/UDP): Pi-hole DNS (commented out by default)

**These services are HTTP-only and should not be directly exposed to the internet.**

For production use:
- Keep these services on a private network
- Use a VPN for remote access
- Consider adding HTTPS via a reverse proxy (e.g., Caddy, Nginx with Let's Encrypt)

### Privileged Containers

- **Pi-hole**: Requires `CAP_NET_ADMIN` for DNS functionality - this is necessary and cannot be removed
- **GPIO Access** (commented by default): Requires `privileged: true` for hardware access on Raspberry Pi

## Security Scanning

ServicePi uses the following tools for security scanning:

- **Trivy**: Vulnerability scanning of Docker images and filesystem
- **shellcheck**: Static analysis of shell scripts
- **Docker Compose validation**: Configuration syntax checking

### Running Security Scans Locally

```bash
# Install Trivy
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Scan the repository
cd /opt/servicepi
trivy fs .

# Scan a specific Docker image
trivy image portainer/portainer-ce:latest

# Install shellcheck
sudo apt-get install shellcheck

# Check scripts
shellcheck scripts/*.sh
```

## Compliance and Standards

ServicePi follows security best practices from:

- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [GitHub Security Best Practices](https://docs.github.com/en/code-security)
- [Portainer Security Considerations](https://docs.portainer.io/admin/environments/add/docker/linux#security-considerations)

## Additional Resources

- [Docker Security Documentation](https://docs.docker.com/engine/security/)
- [Raspberry Pi Security Guide](https://www.raspberrypi.com/documentation/computers/configuration.html#securing-your-raspberry-pi)
- [Home Assistant Security](https://www.home-assistant.io/docs/configuration/securing/)
- [Pi-hole Security](https://docs.pi-hole.net/main/security/)

## Version History

### 2024-10-12
- Initial security policy created
- Added vulnerability reporting guidelines
- Documented security best practices
- Added known security considerations

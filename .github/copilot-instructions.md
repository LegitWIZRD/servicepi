# ServicePi Docker Container Management System

ServicePi is a Raspberry Pi 5 Docker container management system with automated CI/CD deployment pipeline, SSL-secured services, and infrastructure-as-code configuration.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the info here.**

## Working Effectively

### Bootstrap and Build the System
- Install required dependencies:
  ```bash
  # Install Docker Compose (if not available)
  sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
  
  # Verify tools are available
  docker --version
  docker-compose --version
  shellcheck --version
  openssl version
  ```

- Validate configuration files:
  ```bash
  # Validate Docker Compose configuration - takes ~0.025s
  docker-compose config
  
  # Validate shell scripts - takes ~0.8s
  find scripts/ -name "*.sh" -exec shellcheck {} \;
  ```

- Generate SSL certificates:
  ```bash
  # Generate self-signed certificates for testing - takes ~0.4s
  chmod +x configs/nginx/generate-ssl.sh
  ./configs/nginx/generate-ssl.sh localhost self-signed
  
  # For production with real domain:
  ./configs/nginx/generate-ssl.sh your-domain.com letsencrypt
  ```

- Build and start services:
  ```bash
  # NEVER CANCEL: Docker Compose build and start - takes ~1.7s. Set timeout to 300+ seconds.
  docker-compose up -d
  
  # Wait for services to initialize
  sleep 15
  
  # Check service status
  docker-compose ps
  ```

### Service Management Commands
- View service logs:
  ```bash
  # All services - takes ~0.03s
  docker-compose logs
  
  # Specific service
  docker-compose logs nginx-proxy
  docker-compose logs iot-service
  docker-compose logs portainer
  ```

- Restart services:
  ```bash
  # Restart all services
  docker-compose restart
  
  # Restart specific service
  docker-compose restart nginx-proxy
  ```

- Update deployment:
  ```bash
  # Manual update (as root on Pi)
  sudo /opt/servicepi/scripts/update-pi.sh
  
  # Check update script options
  ./scripts/update-pi.sh --help
  ```

## Validation and Testing

### ALWAYS run these validation steps after making changes:

#### HTTP/HTTPS Endpoint Testing
- Test HTTP to HTTPS redirect (~0.01s each):
  ```bash
  # Should return 301 redirect
  curl -I http://localhost/
  ```

- Test HTTPS web dashboard (~0.01s each):
  ```bash
  # Main dashboard health check
  curl -k -f https://localhost/health
  
  # Should return "healthy"
  ```

- Test HTTPS IoT API (~0.01s each):
  ```bash
  # IoT service health check
  curl -k -f https://localhost:8443/health
  
  # IoT sensors endpoint
  curl -k -f https://localhost:8443/api/sensors
  
  # Inter-service communication test
  curl -k -f -X POST https://localhost:8443/api/system/communicate
  ```

- Test HTTPS Portainer (~0.01s):
  ```bash
  # Portainer web interface
  curl -k -I https://localhost:9443
  ```

#### Manual Validation Scenarios
**CRITICAL**: After building and deploying, ALWAYS test these complete user scenarios:

1. **Web Dashboard Scenario**:
   - Access `https://localhost/` in browser (if available)
   - Verify SSL certificate warning (expected with self-signed certs)
   - Check dashboard displays service status information
   - Verify health endpoint returns "healthy" status

2. **IoT API Scenario**:
   - Test all API endpoints: `/health`, `/api/sensors`, `/api/system/communicate`
   - Verify JSON responses are properly formatted
   - Test both GET and POST methods work correctly

3. **Container Management Scenario**:
   - Access Portainer at `https://localhost:9443`
   - Verify container management interface loads
   - Check that all ServicePi containers are visible

### Build and Deployment Timing
**NEVER CANCEL builds or long-running commands. Always use appropriate timeouts:**

- **Docker Compose validation**: ~0.025s - Set timeout to 60s
- **Shell script validation**: ~0.8s - Set timeout to 120s  
- **SSL certificate generation**: ~0.4s - Set timeout to 300s
- **Docker Compose build/start**: ~1.7s - Set timeout to 300s
- **Service health checks**: ~0.01s each - Set timeout to 60s
- **Service logs**: ~0.03s - Set timeout to 60s

## Known Issues and Limitations

### IoT Service Build Issue
- **Issue**: The IoT service Dockerfile requires network access for `pip install` which may fail in restricted environments
- **Workaround**: Use the simplified IoT service for testing:
  ```bash
  # Use simplified Dockerfile that doesn't require network access
  sed -i 's/dockerfile: Dockerfile/dockerfile: Dockerfile.simple/' docker-compose.yml
  docker-compose up -d --build iot-service
  ```
- **Note**: The simplified service provides the same API endpoints but uses Python's built-in HTTP server

### SSL Certificate Warnings
- **Expected behavior**: Self-signed certificates will show browser warnings
- **Production**: Use Let's Encrypt certificates: `./configs/nginx/generate-ssl.sh your-domain.com letsencrypt`

### Nginx Configuration Warnings
- **Expected warnings**: "listen ... http2" directive deprecation warnings are normal and don't affect functionality

## Repository Structure and Key Files

```
servicepi/
├── .github/workflows/ci-cd.yml    # CI/CD pipeline with validation steps
├── configs/
│   ├── nginx/
│   │   ├── proxy/default.conf     # Nginx reverse proxy SSL configuration
│   │   ├── backend/default.conf   # Backend web server configuration  
│   │   └── generate-ssl.sh        # SSL certificate generation script
│   ├── web/index.html             # Main dashboard web content
│   └── iot/
│       ├── Dockerfile             # IoT service container (requires network)
│       ├── Dockerfile.simple      # Simplified IoT service (no network needed)
│       ├── app.py                 # Full Flask IoT API application
│       ├── simple_app.py          # Simplified HTTP server for testing
│       └── requirements.txt       # Python dependencies
├── scripts/
│   ├── install.sh                 # Initial Raspberry Pi installation script
│   ├── update-pi.sh               # Update deployment script  
│   └── setup-nvme-storage.sh      # NVMe storage configuration script
└── docker-compose.yml             # Main service orchestration
```

## Service Architecture

### Services Included
1. **nginx-proxy**: SSL reverse proxy (ports 80, 443, 8443, 9443)
2. **web-backend**: Web dashboard backend (internal only)  
3. **portainer**: Container management interface (internal, accessed via proxy)
4. **iot-service**: IoT API service (internal, accessed via proxy)
5. **certbot**: SSL certificate management (on-demand)

### Network Configuration
- All services run on internal `servicepi-network`
- Only nginx-proxy exposes ports to host
- SSL termination handled by nginx-proxy
- Each service has separate SSL certificates

## NVMe Storage Setup (Raspberry Pi Only)

### CRITICAL: Only run on actual Raspberry Pi hardware
- **Script**: `./scripts/setup-nvme-storage.sh`
- **Purpose**: Configure NVMe drives for Docker container storage
- **Safety**: Automatically excludes boot drive, requires user confirmation
- **Help**: `./scripts/setup-nvme-storage.sh help`

**WARNING**: Do NOT run NVMe setup script in development environments - it formats drives.

## CI/CD Pipeline Commands

### Pipeline Validation Steps (from .github/workflows/ci-cd.yml)
```bash
# Validate Docker Compose
docker-compose config

# Validate shell scripts  
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Generate SSL certificates
chmod +x configs/nginx/generate-ssl.sh
./configs/nginx/generate-ssl.sh localhost self-signed

# Test deployment
docker-compose up -d
sleep 45  # Wait for services to be ready
docker-compose ps

# Test endpoints
curl -I http://localhost/
curl -k -f https://localhost/health
curl -k -f https://localhost:9443
curl -k -f https://localhost:8443/health
curl -k -f https://localhost:8443/api/sensors
curl -k -f -X POST https://localhost:8443/api/system/communicate
```

## Development Workflow

### Making Changes
1. **Always validate first**: Run `docker-compose config` and `shellcheck scripts/*.sh`
2. **Test SSL generation**: Regenerate certificates after nginx config changes  
3. **Build and test**: Use `docker-compose up -d --build` to rebuild changed services
4. **Validate endpoints**: Test all HTTPS endpoints after changes
5. **Check logs**: Use `docker-compose logs` to verify no errors

### Common Development Tasks
- **Modify web dashboard**: Edit `configs/web/index.html`
- **Update nginx config**: Edit `configs/nginx/proxy/default.conf` 
- **Change IoT API**: Edit `configs/iot/app.py` or `configs/iot/simple_app.py`
- **Add new service**: Update `docker-compose.yml` and add nginx proxy config

### Pre-commit Validation
**ALWAYS run before committing changes:**
```bash
# Validate configuration
docker-compose config
find scripts/ -name "*.sh" -exec shellcheck {} \;

# Test deployment  
./configs/nginx/generate-ssl.sh localhost self-signed
docker-compose up -d
sleep 15

# Validate all endpoints
curl -k -f https://localhost/health
curl -k -f https://localhost:8443/health  
curl -k -f https://localhost:8443/api/sensors

# Clean up
docker-compose down
```

This validation ensures your changes will pass the CI/CD pipeline and work correctly on Raspberry Pi deployment.
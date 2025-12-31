# Optional Services Guide

This guide provides detailed instructions for enabling and configuring optional ServicePi services: WordPress and Wazuh.

## Table of Contents

- [WordPress](#wordpress)
  - [Overview](#wordpress-overview)
  - [Requirements](#wordpress-requirements)
  - [Installation](#wordpress-installation)
  - [Configuration](#wordpress-configuration)
  - [Use Cases](#wordpress-use-cases)
- [Wazuh](#wazuh)
  - [Overview](#wazuh-overview)
  - [Requirements](#wazuh-requirements)
  - [Installation](#wazuh-installation)
  - [Configuration](#wazuh-configuration)
  - [Use Cases](#wazuh-use-cases)

---

## WordPress

### WordPress Overview

WordPress is a popular content management system (CMS) that can be used to create a user-friendly dashboard for your ServicePi services. Unlike the technical web dashboard, WordPress provides:

- Visual page builder for creating custom layouts
- Easy-to-use interface for non-technical users
- Ability to create service directories with descriptions
- Blog/documentation capabilities
- Extensive theme and plugin ecosystem

**Example Use Case**: Create a landing page that displays all your ServicePi services with descriptions and clickable links, making it easy for family members to access Home Assistant, Portainer, etc.

### WordPress Requirements

- **Storage**: ~500MB for WordPress + database
- **RAM**: ~256MB minimum
- **Database**: MySQL 8.0 (included in configuration)
- **Network**: Port 8081 available

### WordPress Installation

#### Step 1: Configure Environment Variables

1. Copy and edit the environment file:
   ```bash
   sudo cp /opt/servicepi/.env.example /opt/servicepi/.env  # If not already done
   sudo nano /opt/servicepi/.env
   ```

2. Uncomment and configure WordPress variables:
   ```bash
   # WordPress database configuration
   WORDPRESS_DB_USER=wordpress
   WORDPRESS_DB_PASSWORD=your_secure_password_here
   WORDPRESS_DB_NAME=wordpress
   WORDPRESS_DB_ROOT_PASSWORD=your_secure_root_password_here
   WORDPRESS_TABLE_PREFIX=wp_
   ```

   **⚠️ Important**: Change the default passwords to strong, unique passwords!

   Generate secure passwords:
   ```bash
   openssl rand -hex 32
   ```

#### Step 2: Enable WordPress Services

1. Edit docker-compose.yml:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   ```

2. Find the WordPress section and uncomment these services:
   - `wordpress` service (around line 150)
   - `wordpress-db` service (around line 165)
   - `wordpress_data` volume (around line 203)
   - `wordpress_db` volume (around line 205)

3. In the `nginx-proxy` service section, uncomment:
   - WordPress dependency in `depends_on` section
   - Port `8081:8081` in `ports` section

#### Step 3: Enable Nginx Proxy Configuration

1. Edit nginx proxy configuration:
   ```bash
   sudo nano /opt/servicepi/configs/nginx/proxy/default.conf
   ```

2. Find the commented WordPress server block (around line 260) and uncomment it.

#### Step 4: Configure Firewall

1. Allow WordPress port through firewall:
   ```bash
   sudo ufw allow 8081/tcp
   sudo ufw reload
   ```

#### Step 5: Start WordPress

1. Start WordPress and database services:
   ```bash
   cd /opt/servicepi
   sudo docker compose up -d wordpress wordpress-db
   ```

2. Wait for services to initialize (30-60 seconds):
   ```bash
   sudo docker compose logs -f wordpress
   # Press Ctrl+C when you see "WordPress ready"
   ```

3. Verify services are running:
   ```bash
   sudo docker compose ps | grep wordpress
   ```

#### Step 6: Complete WordPress Setup

1. Access WordPress setup wizard:
   - Via IP: `http://your-pi-ip:8081/`
   - Via domain: `http://wordpress.local:8081/` (if DNS configured)

2. Select your language and click "Continue"

3. Fill in site information:
   - **Site Title**: ServicePi Dashboard (or your choice)
   - **Username**: admin (or your choice)
   - **Password**: Use a strong password
   - **Email**: Your email address
   - **Search Engine Visibility**: Check to discourage search engines

4. Click "Install WordPress"

5. Log in with your credentials

### WordPress Configuration

#### Creating a Service Directory

1. **Install a suitable theme** (optional):
   - Dashboard → Appearance → Themes
   - Search for "directory" or "landing page" themes
   - Install and activate

2. **Create a new page**:
   - Dashboard → Pages → Add New
   - Title: "Services" or "Dashboard"

3. **Add service links** using blocks:
   ```
   ## ServicePi Services
   
   ### Home Automation
   - [Home Assistant](http://homeassistant.local:8123) - Control your smart home
   
   ### Container Management
   - [Portainer](http://portainer.local:9000) - Manage Docker containers
   
   ### Network Services
   - [Pi-hole](http://pihole.local:8053/admin) - Ad blocking dashboard
   
   ### Automation
   - [N8N](http://n8n.local:5678) - Workflow automation
   
   ### IoT
   - [IoT API](http://iot.local:8080) - Device management API
   ```

4. **Set as homepage**:
   - Dashboard → Settings → Reading
   - Front page displays: A static page
   - Select your "Services" page
   - Save Changes

#### Recommended Plugins

- **WP Fastest Cache**: Improve loading speed
- **Limit Login Attempts Reloaded**: Security enhancement
- **Simple Custom CSS**: Easy styling customization

#### Security Best Practices

1. **Change default username** if you used "admin"
2. **Use strong passwords** (20+ characters)
3. **Limit login attempts** via plugin
4. **Keep WordPress updated**:
   ```bash
   # Updates happen automatically via Docker image
   cd /opt/servicepi
   sudo docker compose pull wordpress
   sudo docker compose up -d wordpress
   ```
5. **Regular backups** (see Backup section below)

### WordPress Use Cases

1. **Family Dashboard**: Simple landing page with links to services
2. **Documentation Site**: Document your smart home setup
3. **Service Status Page**: Display which services are available
4. **Tutorial Hub**: Write guides for using ServicePi services
5. **Public Landing Page**: Safe page to expose (without links to internal services)

---

## Wazuh

### Wazuh Overview

Wazuh is a free, open-source security platform that provides:

- **SIEM** (Security Information and Event Management)
- **Threat detection** and incident response
- **Log analysis** and aggregation
- **File integrity monitoring**
- **Vulnerability detection**
- **Compliance management** (PCI-DSS, HIPAA, etc.)
- **Agent-based monitoring** for endpoints

**Example Use Case**: Monitor security events across your Raspberry Pi and other devices on your network, detect intrusions, track file changes, and maintain security compliance.

### Wazuh Requirements

⚠️ **Resource Intensive**: Wazuh requires significant resources!

- **RAM**: Minimum 4GB, 8GB recommended
  - Wazuh Manager: ~512MB
  - OpenSearch Indexer: ~1GB
  - Wazuh Dashboard: ~512MB
- **Storage**: ~2GB for base installation, more for log storage
- **CPU**: Quad-core recommended (Raspberry Pi 5)
- **Network**: Ports 8443 (dashboard), 1514/1515 (agents)

**Check your resources before proceeding:**
```bash
free -h
df -h /opt/docker-storage  # If using NVMe
```

### Wazuh Installation

#### Step 0: Verify Resources

```bash
# Check available RAM (should show 4GB+ available)
free -h

# Check CPU cores (should show 4)
nproc

# Check available disk space (should show 10GB+ free)
df -h
```

If you don't meet these requirements, consider:
- Adding more RAM (if possible)
- Using external storage
- Running Wazuh on a more powerful device

#### Step 1: Configure Environment Variables

1. Edit environment file:
   ```bash
   sudo nano /opt/servicepi/.env
   ```

2. Uncomment and configure Wazuh variables:
   ```bash
   # Wazuh Indexer (OpenSearch) credentials
   WAZUH_INDEXER_USERNAME=admin
   WAZUH_INDEXER_PASSWORD=your_secure_indexer_password_here
   
   # Wazuh API credentials for dashboard access
   WAZUH_API_USERNAME=wazuh-wui
   WAZUH_API_PASSWORD=your_secure_api_password_here
   ```

   **⚠️ Important**: Change ALL default passwords!

   Generate secure passwords:
   ```bash
   openssl rand -hex 32
   ```

#### Step 2: Enable Wazuh Services

1. Edit docker-compose.yml:
   ```bash
   sudo nano /opt/servicepi/docker-compose.yml
   ```

2. Uncomment these services (around line 180):
   - `wazuh-indexer` service
   - `wazuh-manager` service
   - `wazuh-dashboard` service

3. Uncomment Wazuh volumes (around line 208):
   - All `wazuh_*` volumes (10 total)

4. In `nginx-proxy` service section, uncomment:
   - Wazuh dependency in `depends_on`
   - Port `8443:8443` in `ports` section

#### Step 3: Enable Nginx Proxy Configuration

1. Edit nginx proxy configuration:
   ```bash
   sudo nano /opt/servicepi/configs/nginx/proxy/default.conf
   ```

2. Find the commented Wazuh server block (around line 305) and uncomment it.

#### Step 4: Configure Firewall

1. Allow Wazuh ports:
   ```bash
   # Dashboard access
   sudo ufw allow 8443/tcp
   
   # Optional: If you plan to use Wazuh agents
   # sudo ufw allow 1514/tcp  # Agent events
   # sudo ufw allow 1515/tcp  # Agent enrollment
   
   sudo ufw reload
   ```

#### Step 5: Start Wazuh Services

**⚠️ Important**: Start services in order and wait between steps!

1. Start the indexer first:
   ```bash
   cd /opt/servicepi
   sudo docker compose up -d wazuh-indexer
   ```

2. Wait for indexer to be ready (60-90 seconds):
   ```bash
   sudo docker compose logs -f wazuh-indexer
   # Wait for "Node started" message
   # Press Ctrl+C when ready
   
   # Verify indexer is responding
   sleep 30
   curl -k -u admin:your_indexer_password https://localhost:9200
   ```

3. Start the manager:
   ```bash
   sudo docker compose up -d wazuh-manager
   ```

4. Wait for manager to be ready (30-45 seconds):
   ```bash
   sudo docker compose logs -f wazuh-manager
   # Wait for "Wazuh started" message
   # Press Ctrl+C when ready
   ```

5. Start the dashboard:
   ```bash
   sudo docker compose up -d wazuh-dashboard
   ```

6. Wait for dashboard to be ready (45-60 seconds):
   ```bash
   sudo docker compose logs -f wazuh-dashboard
   # Wait for "Server running at" message
   # Press Ctrl+C when ready
   ```

7. Verify all services are running:
   ```bash
   sudo docker compose ps | grep wazuh
   ```

### Wazuh Configuration

#### Initial Dashboard Access

1. Access Wazuh Dashboard:
   - Via IP: `http://your-pi-ip:8443/`
   - Via domain: `http://wazuh.local:8443/` (if DNS configured)

2. Log in with credentials:
   - **Username**: Value of `WAZUH_INDEXER_USERNAME` (default: admin)
   - **Password**: Value of `WAZUH_INDEXER_PASSWORD` from .env

3. Complete initial setup wizard:
   - Accept terms
   - Configure dashboard preferences
   - Skip agent installation for now

#### Installing Wazuh Agents (Optional)

To monitor other devices on your network:

1. **Enable agent ports** (if not already done):
   ```bash
   # Uncomment in docker-compose.yml:
   # ports:
   #   - "1514:1514"  # Agent events
   #   - "1515:1515"  # Agent enrollment
   
   sudo ufw allow 1514/tcp
   sudo ufw allow 1515/tcp
   ```

2. **Restart Wazuh Manager**:
   ```bash
   sudo docker compose restart wazuh-manager
   ```

3. **Add agent from dashboard**:
   - Navigate to Agents → Deploy New Agent
   - Select OS (Windows, Linux, macOS)
   - Enter server address: Your Pi's IP
   - Follow installation commands on target device

4. **Verify agent connection**:
   - Dashboard → Agents
   - Should show "Active" status

#### Useful Wazuh Commands

```bash
# View Wazuh logs
sudo docker compose logs wazuh-manager
sudo docker compose logs wazuh-indexer
sudo docker compose logs wazuh-dashboard

# Restart Wazuh services (in order)
sudo docker compose restart wazuh-indexer
sleep 30
sudo docker compose restart wazuh-manager
sleep 20
sudo docker compose restart wazuh-dashboard

# Check Wazuh manager status
sudo docker exec servicepi-wazuh-manager /var/ossec/bin/wazuh-control status

# List active agents
sudo docker exec servicepi-wazuh-manager /var/ossec/bin/agent_control -l

# Check indexer status
curl -k -u admin:password https://localhost:9200/_cluster/health
```

### Wazuh Use Cases

1. **Security Monitoring**: Monitor authentication attempts, file changes, suspicious processes
2. **Compliance**: Track and report on security compliance (PCI-DSS, HIPAA)
3. **Threat Detection**: Identify malware, rootkits, and intrusion attempts
4. **Log Analysis**: Centralize and analyze logs from all devices
5. **Vulnerability Scanning**: Detect known vulnerabilities in installed software
6. **Incident Response**: Investigate security incidents with detailed logs

---

## Backup and Recovery

### WordPress Backup

```bash
# Backup WordPress files and database
cd /opt/servicepi
sudo docker compose exec wordpress-db mysqldump -u wordpress -p wordpress > wordpress_backup.sql
sudo tar -czf wordpress_files_backup.tar.gz configs/wordpress docker-compose.yml

# Backup WordPress volumes
sudo docker run --rm -v servicepi_wordpress_data:/data -v $(pwd):/backup alpine tar czf /backup/wordpress_data.tar.gz -C /data .
sudo docker run --rm -v servicepi_wordpress_db:/data -v $(pwd):/backup alpine tar czf /backup/wordpress_db.tar.gz -C /data .
```

### Wazuh Backup

```bash
# Backup Wazuh configuration and data
cd /opt/servicepi
sudo docker run --rm -v servicepi_wazuh_etc:/data -v $(pwd):/backup alpine tar czf /backup/wazuh_etc.tar.gz -C /data .
sudo docker run --rm -v servicepi_wazuh_indexer_data:/data -v $(pwd):/backup alpine tar czf /backup/wazuh_indexer_data.tar.gz -C /data .
```

## Troubleshooting

See the main [README.md](../README.md) Troubleshooting section for common issues with WordPress and Wazuh.

## Additional Resources

- [WordPress Documentation](https://wordpress.org/support/)
- [Wazuh Documentation](https://documentation.wazuh.com/)
- [ServicePi Main README](../README.md)
- [Domain Name Resolution Guide](DOMAIN_NAME_RESOLUTION.md)

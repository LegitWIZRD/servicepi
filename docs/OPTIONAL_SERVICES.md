# Optional Services Guide

This guide provides detailed instructions for configuring ServicePi's optional WordPress service.

## Table of Contents

- [WordPress](#wordpress)
  - [Overview](#wordpress-overview)
  - [Requirements](#wordpress-requirements)
  - [Configuration](#wordpress-configuration)
  - [Use Cases](#wordpress-use-cases)

---

## WordPress

### WordPress Overview

WordPress is a popular content management system (CMS) that provides a user-friendly dashboard for your ServicePi services. Unlike the technical web dashboard, WordPress provides:

- Visual page builder for creating custom layouts
- Easy-to-use interface for non-technical users
- Ability to create service directories with descriptions
- Blog/documentation capabilities
- Extensive theme and plugin ecosystem

**WordPress is enabled by default** in ServicePi and is ready to use immediately after installation.

**Example Use Case**: Create a landing page that displays all your ServicePi services with descriptions and clickable links, making it easy for family members to access Portainer, Pi-hole, etc.

### WordPress Requirements

- **Storage**: ~500MB for WordPress + database
- **RAM**: ~256MB minimum
- **Database**: MySQL 8.0 (included and configured)
- **Network**: Port 8081 (configured in firewall)

### WordPress Configuration

WordPress services are **enabled by default** and start automatically with `docker compose up -d`.

#### Step 1: Update Passwords (IMPORTANT!)

1. Edit the environment file:
   ```bash
   sudo nano /opt/servicepi/.env
   ```

2. Change the default WordPress passwords:
   ```bash
   # WordPress database configuration
   WORDPRESS_DB_USER=wordpress
   WORDPRESS_DB_PASSWORD=your_secure_password_here  # CHANGE THIS!
   WORDPRESS_DB_NAME=wordpress
   WORDPRESS_DB_ROOT_PASSWORD=your_secure_root_password_here  # CHANGE THIS!
   WORDPRESS_TABLE_PREFIX=wp_
   ```

   **⚠️ Important**: Change the default passwords to strong, unique passwords!

   Generate secure passwords:
   ```bash
   openssl rand -hex 32
   ```

3. Restart WordPress services:
   ```bash
   cd /opt/servicepi
   sudo docker compose restart wordpress wordpress-db
   ```

#### Step 2: Complete WordPress Setup

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

## Troubleshooting

See the main [README.md](../README.md) Troubleshooting section for common issues with WordPress.

## Additional Resources

- [WordPress Documentation](https://wordpress.org/support/)
- [ServicePi Main README](../README.md)
- [Domain Name Resolution Guide](DOMAIN_NAME_RESOLUTION.md)

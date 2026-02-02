#!/usr/bin/env bash
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
##@Version           :  202602021541-git
# @@Author           :  CasjaysDev
# @@Contact          :  CasjaysDev <docker-admin@casjaysdev.pro>
# @@License          :  MIT
# @@ReadME           :  BlueOnyx 5212R installation for Docker/systemd
# @@Copyright        :  Copyright 2026 CasjaysDev
# @@Created          :  Sun Feb 02 03:41:00 PM EST 2026
# @@File             :  05-custom.sh
# @@Description      :  Install and configure BlueOnyx 5212R control panel
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# shellcheck shell=bash
# shellcheck disable=SC2016
# shellcheck disable=SC2031
# shellcheck disable=SC2120
# shellcheck disable=SC2155
# shellcheck disable=SC2199
# shellcheck disable=SC2317
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set bash options
set -o pipefail
[ "$DEBUGGER" = "on" ] && echo "Enabling debugging" && set -x$DEBUGGER_OPTIONS
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set env variables
exitCode=0
BLUEONYX_VERSION="${BLUEONYX_VERSION:-5212R}"
BLUEONYX_HOSTNAME="${BLUEONYX_HOSTNAME:-blueonyx}"
BLUEONYX_DOMAIN="${BLUEONYX_DOMAIN:-local}"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Predefined actions

echo "=========================================="
echo "Installing BlueOnyx ${BLUEONYX_VERSION}"
echo "=========================================="

# Disable SELinux (required by BlueOnyx)
echo "Disabling SELinux..."
if [ -f /etc/selinux/config ]; then
  sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config
  setenforce 0 2>/dev/null || true
fi

# Install BlueOnyx YUM repository
echo "Installing BlueOnyx repository..."
if ! dnf install -y http://devel.blueonyx.it/pub/${BLUEONYX_VERSION}.rpm; then
  echo "ERROR: Failed to install BlueOnyx repository" >&2
  exitCode=1
  exit $exitCode
fi

# Install BlueOnyx and all dependencies (~900-1200 RPMs)
echo "Installing BlueOnyx packages (this will take several minutes)..."
if ! dnf groupinstall -y blueonyx; then
  echo "ERROR: Failed to install BlueOnyx packages" >&2
  exitCode=1
  exit $exitCode
fi

echo "BlueOnyx packages installed successfully"

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Configure BlueOnyx for container environment

echo "Configuring BlueOnyx for container environment..."

# Create network configuration script wrapper (non-interactive)
cat > /usr/local/bin/blueonyx-network-setup << 'NETSCRIPT'
#!/usr/bin/env bash
# Non-interactive network setup for BlueOnyx in containers

HOSTNAME="${BLUEONYX_HOSTNAME:-blueonyx}"
DOMAIN="${BLUEONYX_DOMAIN:-local}"
FQDN="${HOSTNAME}.${DOMAIN}"

# Set hostname
hostnamectl set-hostname "$FQDN" 2>/dev/null || echo "$FQDN" > /etc/hostname

# Update /etc/hosts
if ! grep -q "$FQDN" /etc/hosts; then
  echo "127.0.0.1   $FQDN $HOSTNAME localhost" > /etc/hosts
  echo "::1         $FQDN $HOSTNAME localhost" >> /etc/hosts
fi

# Set server name in BlueOnyx config if CCEd is available
if [ -x /usr/sausalito/sbin/cced ]; then
  sleep 2
  /usr/sausalito/bin/cceclient set System.hostname "$HOSTNAME" 2>/dev/null || true
  /usr/sausalito/bin/cceclient set System.domainname "$DOMAIN" 2>/dev/null || true
fi

echo "Network configuration set: $FQDN"
NETSCRIPT

chmod +x /usr/local/bin/blueonyx-network-setup

# Create systemd service for BlueOnyx network setup
cat > /etc/systemd/system/blueonyx-network-setup.service << 'SYSTEMDNET'
[Unit]
Description=BlueOnyx Network Setup for Container
After=network.target cced.service
Before=httpd.service admserv.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/blueonyx-network-setup
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SYSTEMDNET

# Initialize BlueOnyx services
echo "Initializing BlueOnyx services..."
if [ -x /usr/sausalito/scripts/initServices.sh ]; then
  /usr/sausalito/scripts/initServices.sh || {
    echo "WARNING: initServices.sh returned non-zero, continuing anyway..."
  }
else
  echo "ERROR: initServices.sh not found" >&2
  exitCode=1
  exit $exitCode
fi

# Fix Apache configuration - load mod_authnz_external
echo "Configuring Apache modules..."
if [ -f /etc/httpd/conf.modules.d/10-auth_external.conf ]; then
  echo "LoadModule authnz_external_module modules/mod_authnz_external.so" >> /etc/httpd/conf.modules.d/10-auth_external.conf
fi

# Generate Dovecot SSL certificates and DH parameters
echo "Configuring Dovecot SSL..."
mkdir -p /etc/pki/dovecot/certs /etc/pki/dovecot/private

# Generate DH parameters (required for SSL)
if [ ! -f /etc/dovecot/dh.pem ]; then
  echo "Generating Dovecot DH parameters (this may take a few minutes)..."
  openssl dhparam -out /etc/dovecot/dh.pem 2048 2>/dev/null || \
    cp /usr/share/dovecot/dh.pem /etc/dovecot/dh.pem 2>/dev/null || \
    echo "Warning: Could not generate DH parameters"
fi

# Generate self-signed CA and certificates if they don't exist
if [ ! -f /etc/pki/dovecot/certs/ca.pem ]; then
  echo "Generating Dovecot CA and certificates..."
  # Generate CA
  openssl req -new -x509 -days 3650 -nodes \
    -out /etc/pki/dovecot/certs/ca.pem \
    -keyout /etc/pki/dovecot/private/ca-key.pem \
    -subj "/C=US/ST=State/L=City/O=BlueOnyx/OU=IT/CN=Dovecot CA" 2>/dev/null || true
  
  # Generate server certificate
  openssl req -new -nodes \
    -out /etc/pki/dovecot/certs/dovecot.csr \
    -keyout /etc/pki/dovecot/private/dovecot.key \
    -subj "/C=US/ST=State/L=City/O=BlueOnyx/OU=IT/CN=localhost" 2>/dev/null || true
  
  openssl x509 -req -in /etc/pki/dovecot/certs/dovecot.csr \
    -CA /etc/pki/dovecot/certs/ca.pem \
    -CAkey /etc/pki/dovecot/private/ca-key.pem \
    -CAcreateserial -days 3650 \
    -out /etc/pki/dovecot/certs/dovecot.pem 2>/dev/null || true
  
  # Create symlink for private key (Dovecot config expects dovecot.pem)
  ln -sf dovecot.key /etc/pki/dovecot/private/dovecot.pem 2>/dev/null || true
  
  # Set permissions
  chmod 600 /etc/pki/dovecot/private/* 2>/dev/null || true
  chmod 644 /etc/pki/dovecot/certs/* 2>/dev/null || true
fi

# Enable BlueOnyx services
echo "Enabling BlueOnyx systemd services..."
systemctl enable cced.service 2>/dev/null || true
systemctl enable admserv.service 2>/dev/null || true
systemctl enable httpd.service 2>/dev/null || true
systemctl enable mysqld.service 2>/dev/null || true
systemctl enable named.service 2>/dev/null || true
systemctl enable dovecot.service 2>/dev/null || true
systemctl enable postfix.service 2>/dev/null || true
systemctl enable proftpd.service 2>/dev/null || true
systemctl enable valkey.service 2>/dev/null || true
systemctl enable blueonyx-network-setup.service 2>/dev/null || true

# Create startup info script
cat > /usr/local/bin/blueonyx-info << 'INFOEOF'
#!/usr/bin/env bash
# Display BlueOnyx access information

HOSTNAME=$(hostname -f 2>/dev/null || hostname)
IP_ADDR=$(hostname -I 2>/dev/null | awk '{print $1}')

cat << INFO

========================================
BlueOnyx Control Panel Ready
========================================

Web Interface (HTTPS):
  https://${IP_ADDR}:444/
  https://${HOSTNAME}:444/

Admin Login:
  Username: admin
  Password: (set on first login)

Root SSH Access:
  Username: root
  Password: blueonyx

Services Status:
  CCEd:       $(systemctl is-active cced 2>/dev/null || echo "unknown")
  AdmServ:    $(systemctl is-active admserv 2>/dev/null || echo "unknown")
  Apache:     $(systemctl is-active httpd 2>/dev/null || echo "unknown")
  MySQL:      $(systemctl is-active mysqld 2>/dev/null || echo "unknown")

========================================

For more info: https://www.blueonyx.it/

INFO
INFOEOF

chmod +x /usr/local/bin/blueonyx-info

# Create container startup wrapper
cat > /usr/local/bin/blueonyx-startup << 'STARTEOF'
#!/usr/bin/env bash
# BlueOnyx container startup tasks

# Wait for key services to be ready (systemctl is-system-running may never return "running" in containers)
echo "Waiting for core services to start..."
timeout=120
count=0
while [ $count -lt $timeout ]; do
  # Check if cced.init is active (most important service)
  if systemctl is-active --quiet cced.init 2>/dev/null; then
    echo "CCEd is active, proceeding with configuration..."
    sleep 2  # Give it a moment to fully initialize
    break
  fi
  sleep 1
  count=$((count + 1))
done

if [ $count -ge $timeout ]; then
  echo "WARNING: CCEd did not start within timeout, continuing anyway..."
fi

# Run network setup
/usr/local/bin/blueonyx-network-setup

# Apply environment variable configuration
/usr/local/bin/blueonyx-env-config

# Display info
/usr/local/bin/blueonyx-info
STARTEOF

chmod +x /usr/local/bin/blueonyx-startup

# Create systemd service to run startup tasks
cat > /etc/systemd/system/blueonyx-startup.service << 'SYSTEMDSTART'
[Unit]
Description=BlueOnyx Container Startup Tasks
After=multi-user.target cced.init.service admserv.service mariadb.service
Wants=cced.init.service admserv.service mariadb.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/local/bin/blueonyx-startup
StandardOutput=journal+console
StandardError=journal+console
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SYSTEMDSTART

systemctl enable blueonyx-startup.service 2>/dev/null || true

# Create persistent data directories
mkdir -p /data/db/mariadb
mkdir -p /data/db/valkey
mkdir -p /data/home
mkdir -p /data/www
mkdir -p /data/mail
mkdir -p /data/dns
mkdir -p /config/blueonyx
mkdir -p /config/mariadb
mkdir -p /config/apache
mkdir -p /config/nginx
mkdir -p /config/postfix
mkdir -p /config/dovecot
mkdir -p /config/bind
mkdir -p /config/proftpd
mkdir -p /config/ssl/certs
mkdir -p /config/ssl/private
mkdir -p /logs

# Create volume mount info
cat > /usr/local/share/template-files/config/README-volumes.txt << 'VOLEOF'
BlueOnyx Container Volumes
==========================

Required volumes for persistent data:

/data/db/mariadb  - MariaDB/MySQL databases
/data/db/valkey   - Valkey (Redis) data
/data/home        - User home directories
/data/www         - Web hosting files
/data/mail        - Mail data (Dovecot)
/data/dns         - BIND DNS zone files
/config/blueonyx  - BlueOnyx configuration
/config/mariadb   - MariaDB configuration
/config/apache    - Apache configuration
/config/nginx     - Nginx configuration
/config/postfix   - Postfix configuration
/config/dovecot   - Dovecot configuration
/config/bind      - BIND configuration
/config/proftpd   - ProFTPD configuration
/config/ssl       - SSL/TLS certificates (self-signed and Let's Encrypt)
  ├── certs/      - Certificate files
  ├── private/    - Private keys
  └── letsencrypt/ - Let's Encrypt certificates
/logs             - All service logs
  └── letsencrypt/ - Certbot logs

Example docker run:
  -v blueonyx-data:/data
  -v blueonyx-config:/config
  -v blueonyx-logs:/logs

VOLEOF

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Main script

echo ""
echo "=========================================="
echo "BlueOnyx ${BLUEONYX_VERSION} installation complete!"
echo "=========================================="
echo ""
echo "IMPORTANT: This container requires:"
echo "  - Privileged mode: --privileged"
echo "  - Cgroup access: -v /sys/fs/cgroup:/sys/fs/cgroup:rw"
echo "  - Port mapping: -p 444:444 -p 81:81"
echo ""
echo "On first start, admin user will be created."
echo "Access the web interface at https://IP:444/"
echo ""

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
# Set the exit code
# exitCode is already set above on errors
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
exit $exitCode

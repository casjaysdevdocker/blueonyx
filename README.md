## 👋 Welcome to blueonyx 🚀  

BlueOnyx 5212R - Full-featured web hosting control panel for AlmaLinux 10

**Note:** BlueOnyx requires systemd and privileged mode to run properly.

## Features

- **Web Hosting** - Apache with mod_php and virtual host management
- **Email Server** - Postfix (satellite mode support) + Dovecot (IMAP/POP3)
- **DNS Server** - BIND with zone management
- **FTP Server** - ProFTPD with virtual users
- **Database** - MariaDB 10.11 with phpMyAdmin
- **Key-Value Store** - Valkey (Redis-compatible) for caching
- **SSL/TLS** - Let's Encrypt support via Certbot with auto-renewal
- **User Management** - Multi-user and reseller support
- **2FA Authentication** - Two-factor authentication support
- **CalDAV/CardDAV** - Calendar and contact synchronization
- **Web GUI** - Full-featured control panel on ports 444 (HTTPS) / 81 (HTTP)
- **40+ ENV Variables** - Extensive configuration via environment variables

## Requirements

- **Platform**: linux/amd64 only (BlueOnyx RPM packages)
- **Docker**: Version 20.10+ with privileged mode support
- **CPU**: x86_64 architecture
- **Memory**: At least 2GB RAM recommended
- **Storage**: Minimum 5GB for container + data
- **Persistent Volumes**: Required for /data and /config

## Quick Start

### Using docker run

```shell
docker run -d \
  --name blueonyx \
  --hostname blueonyx.local \
  --privileged \
  --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v blueonyx-data:/data \
  -v blueonyx-config:/config \
  -p 444:444 \
  -p 81:81 \
  -e BLUEONYX_HOSTNAME=blueonyx \
  -e BLUEONYX_DOMAIN=local \
  casjaysdevdocker/blueonyx:latest
```

### Using docker-compose

```yaml
version: "3.8"
services:
  blueonyx:
    image: casjaysdevdocker/blueonyx:latest
    container_name: blueonyx
    hostname: blueonyx.local
    privileged: true
    cgroup: host
    environment:
      - BLUEONYX_HOSTNAME=blueonyx
      - BLUEONYX_DOMAIN=local
      - TZ=America/New_York
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
      - blueonyx-data:/data
      - blueonyx-config:/config
    ports:
      - "444:444"   # HTTPS Admin Interface
      - "81:81"     # HTTP Admin Interface
      - "80:80"     # HTTP Web Hosting (optional)
      - "443:443"   # HTTPS Web Hosting (optional)
      - "21:21"     # FTP (optional)
      - "25:25"     # SMTP (optional)
      - "110:110"   # POP3 (optional)
      - "143:143"   # IMAP (optional)
    restart: unless-stopped

volumes:
  blueonyx-data:
  blueonyx-config:
```

## First Access

1. Wait 2-3 minutes for BlueOnyx to fully initialize
2. Access the admin panel: https://YOUR_IP:444/ or http://YOUR_IP:81/
3. Default credentials:
   - Username: `admin`
   - Password: Check `/data/ADMIN_PASSWORD.txt` (auto-generated) or set via `BLUEONYX_ADMIN_PASSWORD` ENV var
4. Change the admin password immediately after first login

**Note**: If you set `BLUEONYX_ADMIN_PASSWORD`, use that password. Otherwise, the container generates a random password and saves it to `/data/ADMIN_PASSWORD.txt`.

## Environment Variables

BlueOnyx supports extensive configuration through environment variables:

### Network Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_HOSTNAME` | `blueonyx` | Server hostname |
| `BLUEONYX_DOMAIN` | `local` | Server domain name |
| `BLUEONYX_IPV4` | auto-detected | IPv4 address |
| `BLUEONYX_IPV6` | none | IPv6 address |
| `BLUEONYX_GATEWAY` | auto-detected | Network gateway |
| `BLUEONYX_NAMESERVER` | `8.8.8.8` | DNS nameserver |

### Admin Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_ADMIN_USER` | `admin` | Admin username |
| `BLUEONYX_ADMIN_PASS` | auto-generated | Admin password (saved to `/data/ADMIN_PASSWORD.txt`) |
| `BLUEONYX_ADMIN_EMAIL` | `admin@{domain}` | Admin email address |

### Mail Configuration  
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_POSTFIX_MODE` | `satellite` | Postfix mode (`satellite`, `internet`, `local`) |
| `BLUEONYX_POSTFIX_RELAY` | docker gateway | SMTP relay host |
| `BLUEONYX_POSTFIX_RELAY_PORT` | `25` | SMTP relay port |
| `BLUEONYX_POSTFIX_RELAY_USER` | none | SMTP relay username (optional) |
| `BLUEONYX_POSTFIX_RELAY_PASS` | none | SMTP relay password (optional) |
| `BLUEONYX_ENABLE_DOVECOT` | `yes` | Enable Dovecot IMAP/POP3 |
| `BLUEONYX_ENABLE_SPAM_FILTER` | `yes` | Enable SpamAssassin |
| `BLUEONYX_ENABLE_ANTIVIRUS` | `yes` | Enable ClamAV |
| `BLUEONYX_ENABLE_DKIM` | `yes` | Enable DKIM signing |

### Database Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_DB_TYPE` | `mariadb` | Database type |
| `BLUEONYX_DB_ROOT_PASS` | auto-generated | MySQL root password (saved to `/data/MYSQL_ROOT_PASSWORD.txt`) |
| `BLUEONYX_ENABLE_POSTGRES` | `no` | Enable PostgreSQL |

### Valkey/Redis Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_VALKEY_ENABLED` | `yes` | Enable Valkey (Redis-compatible) |
| `BLUEONYX_VALKEY_PORT` | `6379` | Valkey port |
| `BLUEONYX_VALKEY_MAXMEMORY` | `256mb` | Maximum memory for Valkey |

### Web Server Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_WEB_PROXY` | `nginx` | Web proxy (`nginx`, `apache`) |
| `BLUEONYX_HTTP2_ENABLED` | `yes` | Enable HTTP/2 |
| `BLUEONYX_TLS_VERSION` | `1.3` | Minimum TLS version |
| `BLUEONYX_ENABLE_SSL` | `yes` | Enable SSL/TLS |
| `BLUEONYX_SSL_TYPE` | `selfsigned` | SSL certificate type |

### Certbot/Let's Encrypt
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_CERTBOT_ENABLED` | `no` | Enable Certbot for Let's Encrypt |
| `BLUEONYX_CERTBOT_EMAIL` | admin email | Email for Let's Encrypt notifications |
| `BLUEONYX_CERTBOT_DOMAINS` | none | Comma-separated list of domains for certificates |
| `BLUEONYX_CERTBOT_WEBROOT` | `/var/www/html` | Webroot path for ACME challenge |

### DNS Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_ENABLE_DNS` | `yes` | Enable BIND DNS server |
| `BLUEONYX_DNS_FORWARDERS` | `8.8.8.8 8.8.4.4` | DNS forwarders |

### FTP Configuration
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_ENABLE_FTP` | `yes` | Enable ProFTPD |
| `BLUEONYX_FTP_PASSIVE_PORTS` | `30000-30100` | Passive port range |

### Virtual Hosts
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_VHOSTS` | none | Comma-separated list of virtual hosts to create (e.g., `example.com,test.com`) |

### Feature Toggles
| Variable | Default | Description |
|----------|---------|-------------|
| `BLUEONYX_ENABLE_CALDAV` | `yes` | Enable CalDAV |
| `BLUEONYX_ENABLE_DOCKER` | `yes` | Enable Docker GUI |
| `BLUEONYX_ENABLE_WEBALIZER` | `yes` | Enable Webalizer stats |
| `TZ` | `America/New_York` | Timezone |

### Example with all Mail Configuration
```bash
docker run -d --name blueonyx --privileged --cgroupns=host \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -v blueonyx-data:/data \
  -v blueonyx-config:/config \
  -v blueonyx-logs:/logs \
  -p 444:444 -p 81:81 -p 80:80 -p 443:443 -p 25:25 \
  -e BLUEONYX_HOSTNAME=mail \
  -e BLUEONYX_DOMAIN=example.com \
  -e BLUEONYX_ADMIN_EMAIL=admin@example.com \
  -e BLUEONYX_POSTFIX_MODE=satellite \
  -e BLUEONYX_POSTFIX_RELAY=smtp.sendgrid.net \
  -e BLUEONYX_POSTFIX_RELAY_PORT=587 \
  -e BLUEONYX_POSTFIX_RELAY_USER=apikey \
  -e BLUEONYX_POSTFIX_RELAY_PASS=SG.xxxxx \
  -e BLUEONYX_VHOSTS=site1.example.com,site2.example.com,api.example.com \
  -e BLUEONYX_VALKEY_ENABLED=yes \
  -e BLUEONYX_VALKEY_MAXMEMORY=512mb \
  -e BLUEONYX_CERTBOT_ENABLED=yes \
  -e BLUEONYX_CERTBOT_EMAIL=ssl@example.com \
  -e BLUEONYX_CERTBOT_DOMAINS=example.com,www.example.com \
  casjaysdevdocker/blueonyx:latest
```
## Persistent Data

The container uses volumes for persistent storage following the schema:

### Data Volumes
- `/data/db/mariadb` - MariaDB/MySQL database files
- `/data/db/valkey` - Valkey (Redis) data files
- `/data/home` - User home directories  
- `/data/www` - Web hosting files
- `/data/mail` - Mail storage (Dovecot)
- `/data/dns` - DNS zone files (BIND)

### Configuration Volumes
- `/config/blueonyx` - BlueOnyx main configuration
- `/config/mariadb` - MariaDB/MySQL configuration
- `/config/apache` - Apache web server configuration
- `/config/nginx` - Nginx proxy configuration
- `/config/postfix` - Postfix mail server configuration
- `/config/dovecot` - Dovecot IMAP/POP3 configuration
- `/config/bind` - BIND DNS server configuration
- `/config/proftpd` - ProFTPD FTP server configuration
- `/config/ssl` - SSL/TLS certificates
  - `/config/ssl/certs/` - Certificate files
  - `/config/ssl/private/` - Private keys
  - `/config/ssl/letsencrypt/` - Let's Encrypt certificates

### Log Volumes
- `/logs` - All service logs
  - `/logs/letsencrypt/` - Certbot logs

### Example Volume Mounts
```bash
docker run -d \
  -v blueonyx-data:/data \
  -v blueonyx-config:/config \
  -v blueonyx-logs:/logs \
  casjaysdevdocker/blueonyx
```
## Exposed Ports

| Port | Service | Protocol |
|------|---------|----------|
| 444 | Admin HTTPS | TCP |
| 81 | Admin HTTP | TCP |
| 80 | Web HTTP | TCP |
| 443 | Web HTTPS | TCP |
| 21 | FTP | TCP |
| 25 | SMTP | TCP |
| 110 | POP3 | TCP |
| 143 | IMAP | TCP |
| 53 | DNS | TCP/UDP |
| 6379 | Valkey/Redis | TCP |

## What's Included

This container includes a fully functional BlueOnyx 5212R installation with:

- **BlueOnyx Core** (~1200 RPM packages)
- **Apache** with mod_php and mod_authnz_external
- **MariaDB 10.11** database server
- **Postfix** mail server with satellite mode support
- **Dovecot** IMAP/POP3 server with auto-generated SSL certificates
- **BIND** DNS server with zone management
- **ProFTPD** FTP server
- **Valkey** Redis-compatible key-value store
- **Certbot** for Let's Encrypt SSL certificate automation
- **PHP** with multiple versions support
- **All required dependencies** pre-installed and configured

### Recent Enhancements

**Version 2.0 (2026-02):**
- ✅ Added Valkey (Redis-compatible) support
- ✅ Integrated Certbot with automatic SSL renewal
- ✅ Implemented 40+ environment variables for configuration
- ✅ Added virtual host auto-creation via `BLUEONYX_VHOSTS`
- ✅ Postfix satellite mode with Docker gateway auto-detection
- ✅ Password auto-generation with secure storage
- ✅ Fixed Apache mod_authnz_external module loading
- ✅ Fixed Dovecot SSL certificate generation
- ✅ Improved startup service reliability
- ✅ Platform-restricted to linux/amd64 for stability

## Important Notes

### Privileged Mode Required

BlueOnyx manages multiple system services (Apache, MySQL, DNS, mail) and requires:
- `--privileged` flag
- Access to `/sys/fs/cgroup`
- systemd as PID 1

This is **by design** - BlueOnyx is a full control panel, not a single-service app.

### No Reboot Needed

Unlike bare-metal installation, the container version handles all initialization automatically. No container restart is required after first boot.

### SELinux

SELinux is automatically disabled in the container (required by BlueOnyx).

## Troubleshooting

### Check All Service Status
```shell
docker exec blueonyx systemctl status cced.init admserv httpd mariadb postfix named dovecot valkey
```

### Check Individual Services
```shell
docker exec blueonyx systemctl status cced.init
docker exec blueonyx systemctl status httpd
docker exec blueonyx systemctl status mariadb
docker exec blueonyx systemctl status postfix
docker exec blueonyx systemctl status dovecot
```

### View Logs
```shell
# Container logs
docker logs blueonyx

# Service-specific logs
docker exec blueonyx journalctl -u cced.init -f
docker exec blueonyx journalctl -u httpd -f
docker exec blueonyx journalctl -u blueonyx-startup -f
```

### Access Shell
```shell
docker exec -it blueonyx /bin/bash
```

### Check Generated Passwords
```shell
docker exec blueonyx cat /data/ADMIN_PASSWORD.txt
docker exec blueonyx cat /data/MYSQL_ROOT_PASSWORD.txt
```

### Test Valkey Connection
```shell
docker exec blueonyx valkey-cli ping
docker exec blueonyx valkey-cli INFO
```

### Verify Virtual Hosts
```shell
docker exec blueonyx ls -la /etc/httpd/conf.d/vhost_*.conf
```

### Common Issues

**Services not starting**: Wait 2-3 minutes after container start. BlueOnyx initializes multiple services sequentially.

**Port conflicts**: Ensure ports 444, 81, 80, 443 are not in use by other containers/services.

**Permission errors**: Container must run with `--privileged` flag and cgroupfs access.

**Dovecot fails**: SSL certificates are auto-generated. Check `/etc/pki/dovecot/` for certificates.

**httpd fails**: Ensure Apache modules are loaded. Check logs with `journalctl -u httpd`.

## Get Source Files

```shell
git clone "https://github.com/casjaysdevdocker/blueonyx" "$HOME/Projects/github/casjaysdevdocker/blueonyx"
cd "$HOME/Projects/github/casjaysdevdocker/blueonyx"
```

## Build Container

```shell
cd "$HOME/Projects/github/casjaysdevdocker/blueonyx"
docker build -t blueonyx:local .
```

## More Information

- BlueOnyx Official Site: https://www.blueonyx.it/
- Documentation: https://www.blueonyx.it/index.php?page=features
- Mailing List: https://www.blueonyx.it/index.php?page=mailing-list

## Authors

🤖 casjay: [Github](https://github.com/casjay) 🤖  
⛵ casjaysdevdocker: [Github](https://github.com/casjaysdevdocker) [Docker](https://hub.docker.com/u/casjaysdevdocker) ⛵  

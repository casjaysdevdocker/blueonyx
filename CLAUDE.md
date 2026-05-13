# blueonyx — Docker Migration Notes

## What this image is
BlueOnyx 5212R control panel running on AlmaLinux 10 with systemd (almalinux/10-init).
BlueOnyx is a full server control panel managing Apache, Postfix, ProFTPD, BIND, MariaDB, Dovecot, etc.

## Special architecture: systemd container
- Base: `almalinux/10-init` (systemd init variant)
- Single-stage build — **no** `FROM scratch` final stage (systemd images cannot be stripped)
- PID 1: `CMD ["/sbin/init"]` — systemd, not tini+entrypoint.sh
- **No init.d scripts** — systemd units handle all service lifecycle
- Only supports `linux/amd64` (BlueOnyx is x86-only)

## Build notes
- `05-custom.sh` downloads and installs BlueOnyx via `dnf groupinstall -y blueonyx` (~900-1200 RPMs)
- BlueOnyx RPM repo: `http://devel.blueonyx.it/pub/5212R.rpm`
- Build takes 20-40 minutes
- `initServices.sh` may fail during build (no systemd at build time) — error is caught

## Runtime requirements
```
docker run --privileged -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 444:444 -p 81:81 -p 80:80 -p 443:443 \
  casjaysdevdocker/blueonyx
```
- Must run with `--privileged` for systemd
- Cgroup v2 mount required

## Volumes
- `/data` — persistent data (mariadb, mail, web, dns)
- `/config` — service configs
- `/logs` — all service logs

## Key scripts
- `rootfs/usr/local/bin/blueonyx-env-config` — applies env vars to BlueOnyx at runtime
- `rootfs/usr/local/bin/blueonyx-startup` — container startup tasks (runs via systemd unit)
- `rootfs/usr/local/bin/blueonyx-info` — displays access info
- `rootfs/root/docker/setup/05-custom.sh` — main BlueOnyx installer

## Env vars (runtime)
- `BLUEONYX_HOSTNAME` — hostname (default: blueonyx)
- `BLUEONYX_DOMAIN` — domain (default: local)
- `BLUEONYX_ADMIN_PASS` — admin password
- `BLUEONYX_VERSION` — BlueOnyx version (default: 5212R)

## What was fixed (2026-05-13)
- `02-packages.sh`: Removed broken `reboot` and `sudo dnf update` commands
- `03-files.sh`: Removed irrelevant incus binary download (fails in buildx)
- `Dockerfile`: Updated BUILD_DATE to 202605131434

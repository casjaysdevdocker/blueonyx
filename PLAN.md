# blueonyx Migration Plan

## Status: In Progress

## Architecture decision
BlueOnyx is a full RHEL-based server control panel that requires systemd.
- Base: `almalinux/10-init` (systemd-enabled AlmaLinux 10)
- Single-stage build (no FROM scratch stripping)
- CMD: `/sbin/init` (systemd as PID 1)
- No tini entrypoint; no init.d framework
- amd64 only

## Steps

- [x] Read existing Dockerfile and all setup scripts
- [x] Identify and fix `02-packages.sh` (remove `reboot`, `sudo dnf` lines)
- [x] Identify and fix `03-files.sh` (remove irrelevant incus download)
- [x] Update BUILD_DATE
- [x] Create CLAUDE.md
- [ ] Build image (`docker buildx build --platform linux/amd64`)
- [ ] Smoke test (container starts, systemd runs, web UI reachable on port 444)
- [ ] Commit and push

## Build command
```bash
cd /root/Projects/github/casjaysdevdocker/blueonyx
docker buildx --builder blueonyx build \
  --platform linux/amd64 \
  --tag casjaysdevdocker/blueonyx:latest \
  --push .
```

## Smoke test
```bash
docker run -d --privileged \
  -v /sys/fs/cgroup:/sys/fs/cgroup:rw \
  -p 10444:444 -p 10081:81 \
  --name test-blueonyx \
  casjaysdevdocker/blueonyx:latest
# Wait 30s, check systemd is running
docker exec test-blueonyx systemctl status 2>/dev/null | head -5
docker rm -f test-blueonyx
```

## Known limitations
- Build takes 20-40 minutes (900-1200 RPMs from BlueOnyx + AlmaLinux repos)
- `initServices.sh` may warn during build (no systemd at build time) — expected
- Runtime requires `--privileged` and cgroup v2 mount

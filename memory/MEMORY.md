# Antigravity Dev Container - Session Notes

## Key Architecture Facts
- Image: `ghcr.io/cpfarhood/devcontainer:latest` (repo name is `devcontainer`, not `antigravity`)
- `imagePullPolicy: Always` in statefulset (set during initial deployment debugging)
- Service must NOT be headless (`clusterIP: None`) — Cilium gateway can't route to headless services
- `SECURE_CONNECTION=0` — TLS is terminated at the gateway, not the app
- Container user is `user` (UID 1000) — baseimage-gui runs startapp.sh as `app` user, sudo is not available
- HTTPRoute is managed by Authentik outpost, not in kustomization

## Cluster Patterns
- External gateway: `external` in `gateway-system`, handles `*.farh.net` on port 443 HTTPS only
- Hostnames must be exactly `*.farh.net` (not `*.subdomain.farh.net`) to match gateway listener
- Authentik outpost Terraform lives in `../kubernetes/terraform/authentik-*-proxy/`
- Outpost config uses `external` gateway for public apps, `internal` for internal apps

## Common Gotchas
- `baseimage-gui` creates user dynamically — don't hardcode usernames in scripts, use numeric UID/GID
- `chown /home` fails (PVC root not owned by container) — only chown subdirectories
- `sudo` not available in startapp.sh — script already runs as correct user

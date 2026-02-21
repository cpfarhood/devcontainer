# Antigravity Dev Container - Session Notes

## Key Architecture Facts
- Image: `ghcr.io/cpfarhood/devcontainer:latest` (repo name is `devcontainer`, not `antigravity`)
- Deployed via Helm chart (`chart/`), not kustomize anymore
- Service must NOT be headless (`clusterIP: None`) — Cilium gateway can't route to headless services
- `SECURE_CONNECTION=0` — TLS is terminated at the gateway, not the app
- Container user is `user` (UID 1000) — baseimage-gui runs startapp.sh as `app` user, sudo is not available

## Deployment Method
- **Primary**: Helm chart in `chart/` directory
- **Makefile targets**: `helm-deploy`, `helm-delete`, `helm-logs`, `helm-shell`, `helm-port-forward`
- **Old kustomize** (`k8s/` directory) has been removed — all deployments use Helm now
- Chart published as OCI artifact to GHCR, reconciled by Flux

## MCP Sidecars
- **Kubernetes MCP** (port 8080): Only deployed when enabled AND `clusterAccess` != `none`
- **Flux MCP** (port 8081): Only deployed when enabled AND `clusterAccess` != `none`
- **Home Assistant MCP** (port 8087): Disabled by default, requires secrets:
  - `homeassistant-url`: Base URL like `http://homeassistant.local:8123`
  - `homeassistant-token`: Long-lived access token
- **Playwright MCP**: External service, not a sidecar
- Configure via `mcpSidecars.<name>.enabled` in values

## Common Gotchas
- `baseimage-gui` creates user dynamically — don't hardcode usernames in scripts, use numeric UID/GID
- `chown /home` fails (PVC root not owned by container) — only chown subdirectories
- `sudo` not available in startapp.sh — script already runs as correct user
- MCP sidecars need appropriate secrets and RBAC permissions to function

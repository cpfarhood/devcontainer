# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Antigravity is a Docker-based cloud development environment that provides:
- Web-based GUI IDE (VSCode/Antigravity) via VNC on port 5800
- Happy Coder AI assistant integration
- Automatic GitHub repository cloning on startup
- Kubernetes-native deployment with persistent home storage

The stack is primarily **Bash scripts + YAML** — there is no Node.js package, compiled language, or test framework.

## Common Commands

### Building

```bash
make build                              # Build Docker image
make build REGISTRY=ghcr.io/myuser IMAGE_TAG=v1.0  # Custom registry/tag
docker build -t ghcr.io/cpfarhood/antigravity:latest .  # Direct build
```

### Running Locally

```bash
GITHUB_REPO="https://github.com/user/repo" make run   # Run with Docker
make stop    # Stop container
make clean   # Remove volumes
```

### Kubernetes Deployment

```bash
GITHUB_REPO="https://github.com/user/repo" make helm-deploy  # Deploy with Helm
make helm-delete          # Tear down Helm release
make helm-port-forward    # Forward port 5800 to localhost
make helm-logs            # Stream container logs
make helm-shell           # Open interactive shell in pod

# Or use Helm directly
helm install mydev ./chart --set name=mydev --set githubRepo=https://github.com/user/repo
```

### Other Useful Targets

```bash
make help   # List all Makefile targets with descriptions
make push   # Push image to registry (build first)
```

## Architecture

### Startup Flow

```
Container start
  → scripts/startapp.sh
    → scripts/init-repo.sh (clone GITHUB_REPO, start Happy Coder)
    → launch VSCode as user `claude` in /workspace
```

### Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Image definition — installs Chrome, Node.js, VSCode, Happy Coder; creates non-root user (UID 1000) |
| `scripts/init-repo.sh` | Clones GitHub repo, authenticates with token, starts Happy Coder background service |
| `scripts/startapp.sh` | Calls init-repo.sh then opens VSCode in the workspace |
| `chart/` | Helm chart for Kubernetes deployment |
| `chart/templates/deployment.yaml` | Deployment spec — main container + MCP sidecar containers |
| `chart/templates/rbac.yaml` | ServiceAccount, Role/ClusterRole based on `clusterAccess` value |
| `chart/templates/pvc.yaml` | PersistentVolumeClaim for user home |
| `chart/templates/service.yaml` | ClusterIP Service (VNC + optional SSH) |
| `chart/values.yaml` | Default Helm values |
| `.mcp.json` | MCP server connection config (Kubernetes, Flux, Playwright) |
| `Makefile` | Build/deploy automation |

### MCP Sidecars

MCP (Model Context Protocol) servers run as sidecar containers in the pod, enabling AI assistants to interact with various services:

| Sidecar | Image | Port | Endpoint | Default |
|---------|-------|------|----------|---------|
| `kubernetes-mcp` | `quay.io/containers/kubernetes_mcp_server` | 8080 | `http://localhost:8080/sse` | Enabled |
| `flux-mcp` | `ghcr.io/controlplaneio-fluxcd/flux-operator-mcp` | 8081 | `http://localhost:8081/sse` | Enabled |
| `homeassistant-mcp` | `ghcr.io/homeassistant-ai/ha-mcp` | 8087 | `http://localhost:8087/sse` | Disabled |

**Note:**
- Kubernetes and Flux sidecars require `clusterAccess` != `none` to be deployed (they need RBAC permissions)
- Kubernetes and Flux sidecars inherit the pod's ServiceAccount RBAC permissions
- Home Assistant sidecar requires `HOMEASSISTANT_URL` and `HOMEASSISTANT_TOKEN` in the env secret
- Playwright MCP remains an external service

#### Enabling/Disabling MCP Servers

To control MCP sidecars, set the `enabled` flag in your values override:

```yaml
# Disable all MCP sidecars
mcpSidecars:
  kubernetes:
    enabled: false
  flux:
    enabled: false
  homeassistant:
    enabled: false

# Or selectively enable/disable
mcpSidecars:
  kubernetes:
    enabled: true  # Keep Kubernetes MCP enabled
  flux:
    enabled: false # Disable Flux MCP
  homeassistant:
    enabled: true  # Enable Home Assistant MCP (requires secrets)
```

When deploying via Helm:
```bash
# Using --set flag
helm install my-devcontainer ./chart --set mcpSidecars.kubernetes.enabled=false --set mcpSidecars.flux.enabled=false

# Or with a values file
helm install my-devcontainer ./chart -f custom-values.yaml
```

### Storage Model

- `/config` — ReadWriteMany PVC (persists across pod restarts, holds user config/dotfiles)
- `/workspace` — emptyDir by default (ephemeral; can be changed to PVC)

### Environment Variables

**Required:**
- `GITHUB_REPO` — URL of repository to clone into `/workspace`

**Optional:**
- `GITHUB_TOKEN` — PAT for private repo access
- `VNC_PASSWORD` — VNC web interface password
- `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` — VNC resolution
- `USER_ID` / `GROUP_ID` — Override UID/GID (default 1000)
- `HAPPY_SERVER_URL` / `HAPPY_WEBAPP_URL` — Custom Happy Coder endpoints
- `HAPPY_HOME_DIR` / `HAPPY_EXPERIMENTAL`

### CI/CD

- **`build-and-push.yaml`** — Builds and pushes to GHCR on every push to `main`, version tags (`v*`), and PRs. Tags: `latest` (main), semver, branch name, commit SHA.
- **`release.yaml`** — Creates a GitHub Release with docker pull instructions when a version tag is pushed.
- **`dependabot.yml`** — Weekly updates for GitHub Actions and Docker base image.

Image registry: `ghcr.io/cpfarhood/devcontainer`

## Kubernetes Notes

- Deployed via Helm chart (`chart/`), published as OCI artifact to GHCR, reconciled by Flux
- Storage class is `ceph-filesystem` by default — change via `storage.className` in values
- Resource limits: 1–4 CPU, 2–8Gi memory
- Health checks (liveness/readiness probes) on port 5800
- Secrets: optional env Secret (`devcontainer-{name}-secrets-env`) for `GITHUB_TOKEN`, `VNC_PASSWORD`, etc.
- RBAC: controlled by `clusterAccess` value (`none`, `readonlyns`, `readwritens`, `readonly`, `readwrite`)

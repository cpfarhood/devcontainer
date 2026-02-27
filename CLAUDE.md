# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

The Dev Container is a Docker-based cloud development environment that provides:
- Web-based GUI IDE (VSCode/Antigravity) via VNC on port 5800
- Claude Code, OpenCode, and Crush AI coding agents (terminal-based)
- Built-in web file manager for uploading/downloading files (optional, via `fileManager.enabled`)
- Automatic GitHub repository cloning on startup
- Kubernetes-native deployment with persistent home storage
- MCP (Model Context Protocol) sidecars for AI assistant integrations

The stack is primarily **Bash scripts + YAML** — there is no Node.js package, compiled language, or test framework.

## Common Commands

### Building

```bash
make build                              # Build Docker image
make build REGISTRY=ghcr.io/myuser IMAGE_TAG=v1.0  # Custom registry/tag
docker build -t ghcr.io/cpfarhood/devcontainer:latest .  # Direct build
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
    → scripts/init-repo.sh
      → Configure git user & credentials
      → Clone GITHUB_REPO (if set)
    → Launch VSCode as user `user` in /workspace
```

### Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Image definition — installs Chrome, VSCode, Helm, gh CLI, kubeseal, Claude Code, OpenCode, Crush; creates non-root user (UID 1000) |
| `scripts/init-repo.sh` | Configures git credentials, clones GitHub repo |
| `scripts/startapp.sh` | Calls init-repo.sh then opens VSCode in the workspace |
| `chart/` | Helm chart for Kubernetes deployment |
| `chart/templates/deployment.yaml` | Deployment spec — main container + MCP sidecar containers |
| `chart/templates/rbac.yaml` | ServiceAccount, Role/ClusterRole based on `clusterAccess` value |
| `chart/templates/pvc.yaml` | PersistentVolumeClaim for user home |
| `chart/templates/service.yaml` | ClusterIP Service (VNC + optional SSH) |
| `chart/values.yaml` | Default Helm values |
| `.mcp.json` | MCP server connection config (GitHub Copilot, Kubernetes, Flux, Helm, Fetch, Sequential Thinking, Playwright, pgtuner) |
| `Makefile` | Build/deploy automation |

### MCP Sidecars

MCP (Model Context Protocol) servers run as sidecar containers in the pod, enabling AI assistants to interact with various services:

| Sidecar | Image | Version | Port | Endpoint | Default |
|---------|-------|---------|------|----------|---------|
| `kubernetes-mcp` | `quay.io/containers/kubernetes_mcp_server` | v0.0.57 | 8080 | `http://localhost:8080/sse` | Enabled |
| `flux-mcp` | `ghcr.io/controlplaneio-fluxcd/flux-operator-mcp` | v0.41.1 | 8081 | `http://localhost:8081/sse` | Enabled |
| `helm-mcp` | `ghcr.io/zekker6/mcp-helm` | v1.3.1 | 8012 | `http://localhost:8012/sse` | Enabled |
| `fetch-mcp` | `mcp/fetch` | latest | 8082 | `http://localhost:8082/sse` | Enabled |
| `sequentialthinking-mcp` | `mcp/sequentialthinking` | latest | 8083 | `http://localhost:8083/sse` | Enabled |
| `homeassistant-mcp` | `ghcr.io/homeassistant-ai/ha-mcp` | stable | 8087 | `http://localhost:8087/sse` | Disabled |
| `pgtuner-mcp` | `dog830228/pgtuner_mcp` | latest | 8085 | `http://localhost:8085/sse` | Disabled |
| `playwright-mcp` | `mcr.microsoft.com/playwright/mcp` | latest | 8086 | `http://localhost:8086/sse` | Enabled |

**Note:**
- GitHub MCP is accessed via the Copilot API (`https://api.githubcopilot.com/mcp/`), not as a sidecar
- Kubernetes and Flux sidecars require `clusterAccess` != `none` to be deployed (they need RBAC permissions)
- Kubernetes and Flux sidecars inherit the pod's ServiceAccount RBAC permissions
- Helm sidecar enables browsing Helm repositories and chart metadata
- Fetch sidecar provides web content fetching capabilities and HTML to markdown conversion
- Sequential thinking sidecar enables structured thinking and problem-solving processes
- Home Assistant sidecar requires `HOMEASSISTANT_URL` and `HOMEASSISTANT_TOKEN` in the env secret
- PostgreSQL tuner sidecar requires `DATABASE_URI` in the env secret (PostgreSQL connection string)
- Playwright sidecar provides browser automation and web testing capabilities

#### Enabling/Disabling MCP Servers

To control MCP sidecars, set the `enabled` flag in your values override:

```yaml
# Disable all MCP sidecars
mcp:
  sidecars:
    kubernetes:
      enabled: false
    flux:
      enabled: false
    helm:
      enabled: false
    fetch:
      enabled: false
    sequentialthinking:
      enabled: false
    homeassistant:
      enabled: false
    pgtuner:
      enabled: false
    playwright:
      enabled: false

# Or selectively enable/disable
mcp:
  sidecars:
    kubernetes:
      enabled: true  # Keep Kubernetes MCP enabled
    flux:
      enabled: false # Disable Flux MCP
    helm:
      enabled: true  # Enable Helm MCP for chart browsing
    fetch:
      enabled: true  # Enable Fetch MCP for web content fetching
    sequentialthinking:
      enabled: true  # Enable Sequential Thinking MCP for problem-solving
    homeassistant:
      enabled: true  # Enable Home Assistant MCP (requires secrets)
    pgtuner:
      enabled: true  # Enable PostgreSQL tuner MCP (requires DATABASE_URI)
    playwright:
      enabled: true  # Enable Playwright MCP for browser automation
```

When deploying via Helm:
```bash
# Quick start (recommended)
cp chart/values-quickstart.yaml my-values.yaml
# Edit name and githubRepo in my-values.yaml
helm install my-devcontainer ./chart -f my-values.yaml

# Using --set flags
helm install my-devcontainer ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/user/repo \
  --set mcp.sidecars.kubernetes.enabled=false

# Full customization
helm install my-devcontainer ./chart -f custom-values.yaml
```

### Storage Model

- `/config` — ReadWriteMany PVC (persists across pod restarts, holds user config/dotfiles)
- `/workspace` — emptyDir by default (ephemeral; can be changed to PVC)

### Environment Variables

**Required:**
- `GITHUB_REPO` — URL of repository to clone into `/workspace`

**Optional:**
- `GITHUB_TOKEN` — PAT for private repo access (automatically configures git credentials)
- `GIT_USER_NAME` — Git user name for commits (default: "DevContainer User")
- `GIT_USER_EMAIL` — Git user email for commits (default: "devcontainer@example.com")
- `GITLAB_HOST` — GitLab hostname if using GitLab with same token
- `VNC_PASSWORD` — VNC web interface password
- `DISPLAY_WIDTH` / `DISPLAY_HEIGHT` — VNC resolution
- `USER_ID` / `GROUP_ID` — Override UID/GID (default 1000)
- `WEB_FILE_MANAGER` — Set to `1` to enable the built-in web file manager (controlled via `fileManager.enabled` in Helm values)
- `WEB_FILE_MANAGER_ALLOWED_PATHS` — Paths accessible by the file manager (default: `/workspace,/config`)
- `WEB_FILE_MANAGER_DENIED_PATHS` — Paths to deny access to (takes precedence over allowed)

### CI/CD

- **`build-and-push.yaml`** — Builds and pushes to GHCR on every push to `main`, version tags (`v*`), and PRs. Tags: `latest` (main), semver, branch name, commit SHA.
- **`release-unified.yaml`** — Manual release workflow: bumps chart version, builds Docker image, publishes Helm chart to GitHub Pages (`https://cpfarhood.github.io/devcontainer`), and creates GitHub Release.
- **`dependabot.yml`** — Weekly updates for GitHub Actions and Docker base image.

Image registry: `ghcr.io/cpfarhood/devcontainer`
Helm repo: `https://cpfarhood.github.io/devcontainer`

## Kubernetes Notes

- Deployed via Helm chart (`chart/`), published to GitHub Pages Helm repo, reconciled by Flux
- Storage class is `ceph-filesystem` by default — change via `storage.className` in values
- Resource limits: 1–4 CPU, 2–8Gi memory
- Health checks (liveness/readiness probes) on port 5800
- Secrets: optional env Secret (`devcontainer-{name}-secrets-env`) for `GITHUB_TOKEN`, `VNC_PASSWORD`, etc.
- RBAC: controlled by `clusterAccess` value (`none`, `readonlyns`, `readwritens`, `readonly`, `readwrite`)

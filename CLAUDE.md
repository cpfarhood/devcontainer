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
make k8s-deploy          # Deploy via kustomize
kubectl apply -k k8s/    # Direct kustomize apply
make k8s-delete          # Tear down
make k8s-port-forward    # Forward port 5800 to localhost
make k8s-logs            # Stream container logs
make k8s-shell           # Open interactive shell in pod
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
| `Dockerfile` | Image definition — installs Chrome, Node.js, VSCode, Happy Coder; creates non-root user `claude` (UID 1000) |
| `scripts/init-repo.sh` | Clones GitHub repo, authenticates with token, starts Happy Coder background service |
| `scripts/startapp.sh` | Calls init-repo.sh then opens VSCode in the workspace |
| `k8s/statefulset.yaml` | StatefulSet + headless Service; mounts `/home` (PVC) and `/workspace` (emptyDir) |
| `k8s/configmap.yaml` | `GITHUB_REPO`, `HAPPY_SERVER_URL`, `HAPPY_WEBAPP_URL` |
| `k8s/httproute.yaml` | Gateway API HTTPRoute for external browser access |
| `k8s/secrets-example.yaml` | Template for SealedSecrets (GitHub token, VNC password) |
| `Makefile` | Build/deploy automation |

### Storage Model

- `/home` — ReadWriteMany PVC (persists across pod restarts, holds user config/dotfiles)
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

- Uses Kustomize (`kubectl apply -k k8s/`)
- Storage class is `ceph-filesystem` by default — change in `statefulset.yaml` for other clusters
- Resource limits: 1–4 CPU, 2–8Gi memory
- Health checks (liveness/readiness probes) on port 5800
- Secrets managed via SealedSecrets (see `k8s/secrets-example.yaml`)

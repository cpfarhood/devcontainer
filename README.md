# Antigravity Dev Container

![Build and Push](https://github.com/cpfarhood/devcontainer/actions/workflows/build-and-push.yaml/badge.svg)

A containerized cloud development environment with web-based GUI access, featuring:
- **VSCode or Google Antigravity** via browser-based VNC (port 5800)
- **SSH access** option (OpenSSH on port 22, additive with any IDE)
- **Happy Coder** AI assistant backed by Claude
- **Automatic GitHub repo cloning** on startup
- **Persistent home directory** via ReadWriteMany PVC
- **Kubernetes-native** Helm chart deployment

## Quick Start

### 1. Create a secret

The secret is picked up automatically via `envFrom`. Keys recognised:

| Key | Purpose |
|-----|---------|
| `GITHUB_TOKEN` | PAT for private repo access (`repo` scope) |
| `VNC_PASSWORD` | Password for the VNC web UI |
| `ANTHROPIC_API_KEY` | API key — alternative to browser-based Claude login |
| `SSH_AUTHORIZED_KEYS` | Public key(s) for SSH access (required when `ssh: true`) |

```bash
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=VNC_PASSWORD='changeme'
```

Or use SealedSecrets:

```bash
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=VNC_PASSWORD='changeme' \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml | kubectl apply -f -
```

### 2. Deploy with Helm

```bash
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo
```

### 3. Access

```bash
# Local port-forward
kubectl port-forward deployment/devcontainer-mydev 5800:5800
open http://localhost:5800
```

Or configure an ingress / Gateway API HTTPRoute pointing at port 5800.

### 4. Authenticate Claude

On first launch, open a terminal in the VSCode GUI and run:

```bash
claude
```

A Chrome browser window will open inside VNC for the Claude Max OAuth login. Credentials are stored on the home PVC and persist across pod restarts.

---

## Helm Chart Reference

### Core values

| Value | Default | Description |
|-------|---------|-------------|
| `name` | `""` | Instance name — used in all resource names (`devcontainer-{name}`) |
| `githubRepo` | `""` | Repository to clone into `/workspace` on startup |
| `ide` | `vscode` | IDE to launch — `vscode`, `antigravity`, or `none` (see below) |
| `ssh` | `false` | Also start an OpenSSH server on port 22 (additive, any `ide`) |
| `image.repository` | `ghcr.io/cpfarhood/devcontainer` | Container image |
| `image.tag` | `latest` | Image tag |

### IDE choice

`ide` controls what GUI is launched in the VNC session:

| Value | Port | Description |
|-------|------|-------------|
| `vscode` (default) | 5800 (VNC) | VSCode desktop via browser-based VNC |
| `antigravity` | 5800 (VNC) | Google Antigravity (VSCode fork with AI) via VNC |
| `none` | — | No IDE; container stays alive (useful when `ssh: true`) |

### SSH access

`ssh: true` starts OpenSSH on port 22 **in addition to** the IDE. It works with any `ide` value:

```bash
# SSH-only (no VNC)
helm install mydev ./chart --set name=mydev --set ide=none --set ssh=true

# VSCode in VNC + SSH access at the same time
helm install mydev ./chart --set name=mydev --set ssh=true
```

Add your public key to the env secret:

```bash
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=SSH_AUTHORIZED_KEYS='ssh-ed25519 AAAA...'
```

Then connect:

```bash
kubectl port-forward deployment/devcontainer-mydev 2222:22
ssh -p 2222 user@localhost
```

### Happy Coder

| Value | Default | Description |
|-------|---------|-------------|
| `happyServerUrl` | `https://happy.farh.net` | Happy Coder server endpoint |
| `happyWebappUrl` | `https://happy-coder.farh.net` | Happy Coder webapp URL |
| `happyHomeDir` | `/home/user/.happy` | Happy runtime state directory (persists on the home PVC) |
| `happyExperimental` | `true` | Enable experimental Happy features |

### Kubernetes cluster access

The `clusterAccess` value provisions a ServiceAccount, Role/ClusterRole, and binding so the devcontainer pod can interact with the Kubernetes API. The default is `none` — no RBAC resources are created.

| Value | Scope | Verbs |
|-------|-------|-------|
| `none` (default) | — | no access |
| `readonlyns` | release namespace | `get`, `list`, `watch` |
| `readwritens` | release namespace | `*` |
| `readonly` | cluster-wide | `get`, `list`, `watch` |
| `readwrite` | cluster-wide | `*` |

```bash
# Give the pod read-only access to its own namespace
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set clusterAccess=readonlyns
```

With any non-`none` value, a `ServiceAccount` named `devcontainer-{name}` is created and set as the pod's `serviceAccountName`, so `kubectl` and any in-cluster API calls use it automatically.

### Display and resources

| Value | Default | Description |
|-------|---------|-------------|
| `display.width` | `1920` | VNC width (px) |
| `display.height` | `1080` | VNC height (px) |
| `secureConnection` | `0` | Set to `1` if TLS is not terminated upstream |
| `userId` | `1000` | UID for the app user |
| `groupId` | `1000` | GID for the app user |
| `storage.size` | `32Gi` | Home PVC size |
| `storage.className` | `ceph-filesystem` | StorageClass (must be ReadWriteMany) |
| `shm.sizeLimit` | `2Gi` | `/dev/shm` size (memory-backed; used by Electron apps) |
| `resources.requests.memory` | `2Gi` | |
| `resources.requests.cpu` | `1000m` | |
| `resources.limits.memory` | `8Gi` | |
| `resources.limits.cpu` | `4000m` | |
| `envSecretName` | `devcontainer-{name}-secrets-env` | Override the secret name |

---

## Architecture

### Startup flow

```
Container start
  → cont-init.d/20-fix-user-shell.sh   — fix shell/home on baseimage-gui app user
  → cont-init.d/25-start-sshd.sh       — start sshd if SSH=true
  → /startapp.sh  (runs as app user, UID 1000)
      → init-repo.sh
          → clone / pull GITHUB_REPO into /workspace/{repo}
          → rm daemon.state.json.lock    — clear stale Happy lock
          → happy daemon start           — starts Happy Coder background daemon
      → IDE=vscode:      code --new-window --wait /workspace/{repo}
        IDE=antigravity:  antigravity --no-sandbox --user-data-dir ~/.config/antigravity ... /workspace/{repo}
        IDE=none:         sleep infinity
      (SSH=true: sshd also running as root on port 22; host keys persisted on PVC)
```

### Storage

| Mount | Source | Persistence |
|-------|--------|-------------|
| `/home` | ReadWriteMany PVC (`userhome-{name}`) | Survives pod restarts — stores Claude credentials, dotfiles, git config |
| `/workspace` | `emptyDir` | Ephemeral — repo is re-cloned on each pod start |

Happy Coder's runtime state (`HAPPY_HOME_DIR`) is kept in `/home/user/.happy` on the persistent home PVC, so auth credentials and settings survive pod restarts. A stale lock file (`daemon.state.json.lock`) is removed automatically on each startup.

---

## Troubleshooting

### Happy Coder daemon not starting

```bash
# Check daemon status
happy daemon status

# Start manually (also clears any stale lock)
happy daemon start

# View daemon logs
ls ~/.happy/logs/
```

### Claude not authenticated

Browser-based OAuth login is the primary method (works inside VNC via the Chrome wrapper). If you prefer API key auth:

```bash
kubectl patch secret devcontainer-mydev-secrets-env \
  --type='json' \
  -p='[{"op":"add","path":"/data/ANTHROPIC_API_KEY","value":"'$(echo -n "sk-ant-..." | base64)'"}]'
```

Then restart the pod to pick up the new env var.

### VNC not loading

```bash
kubectl port-forward deployment/devcontainer-mydev 5800:5800
kubectl logs deployment/devcontainer-mydev
kubectl describe pod -l app.kubernetes.io/instance=mydev
```

### Pod not picking up new image after upgrade

The chart uses `image.tag: latest`. Kubernetes won't restart the pod on a Helm upgrade unless the Deployment spec changes. Force a restart manually:

```bash
kubectl rollout restart deployment/devcontainer-mydev
```

### Repository not cloning

```bash
kubectl logs deployment/devcontainer-mydev | grep "Repository Initialization"
kubectl exec deployment/devcontainer-mydev -- env | grep GITHUB
```

---

## Local Docker run

```bash
docker run -d \
  -p 5800:5800 \
  -e GITHUB_REPO="https://github.com/youruser/yourrepo" \
  -e GITHUB_TOKEN="ghp_..." \
  -e VNC_PASSWORD="changeme" \
  -v $(pwd)/home:/home \
  ghcr.io/cpfarhood/devcontainer:latest
```

---

## Building

```bash
docker build -t ghcr.io/cpfarhood/devcontainer:latest .
docker push ghcr.io/cpfarhood/devcontainer:latest
```

The image is also built and pushed automatically by CI on every push to `main` and on version tags (`v*`).

---

## Credits

- Base image: [jlesage/docker-baseimage-gui](https://github.com/jlesage/docker-baseimage-gui)
- AI assistant: [Happy Coder](https://happy.engineering) + [Claude](https://claude.ai)

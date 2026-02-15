# Antigravity Dev Container

A containerized development environment with GUI access, featuring:
- **Antigravity** (VSCode/Cloud IDE) via web browser
- **Happy Coder** - AI-powered development assistant
- **Automatic GitHub repo cloning**
- **Persistent user home directory**
- **Secure non-root execution**

## Features

### GUI Access
- Web-based VNC interface (port 5800)
- Full desktop environment in your browser
- Secure connections with optional password protection

### Development Tools
- Antigravity IDE (VSCode-based)
- Happy Coder AI assistant
- Git integration
- Node.js and npm
- Python 3
- Chrome browser

### Security
- Runs as non-root user `claude` (UID 1000, GID 1000)
- Secure VNC connections
- Token-based GitHub authentication
- Isolated workspace

### Persistence
- ReadWriteMany PVC for `/home` (user data persists)
- Workspace mounted at `/workspace`
- Repository cloned on first startup

## Quick Start

### 1. Build the Image

```bash
docker build -t ghcr.io/cpfarhood/antigravity:latest .
docker push ghcr.io/cpfarhood/antigravity:latest
```

### 2. Configure Secrets

Edit `k8s/secrets-example.yaml` and create a sealed secret:

```bash
kubectl create secret generic antigravity-secrets \
  --from-literal=github-token='ghp_your_token' \
  --from-literal=happy-coder-api-key='your_key' \
  --from-literal=vnc-password='your_password' \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml > k8s/sealedsecrets.yaml
```

### 3. Configure Repository

Edit `k8s/configmap.yaml`:

```yaml
data:
  github-repo: "https://github.com/yourusername/yourrepo"
```

### 4. Deploy to Kubernetes

```bash
kubectl apply -k k8s/
```

### 5. Access the Interface

```bash
# Port forward for local access
kubectl port-forward statefulset/antigravity 5800:5800

# Open in browser
open http://localhost:5800
```

Or configure Ingress for external access.

## Environment Variables

### Required
- `GITHUB_REPO` - GitHub repository URL to clone

### Optional
- `GITHUB_TOKEN` - GitHub Personal Access Token (for private repos)
- `HAPPY_CODER_API_KEY` - API key for Happy Coder
- `VNC_PASSWORD` - Password for VNC access
- `USER_ID` - UID for claude user (default: 1000)
- `GROUP_ID` - GID for claude user (default: 1000)
- `DISPLAY_WIDTH` - VNC display width (default: 1920)
- `DISPLAY_HEIGHT` - VNC display height (default: 1080)

## Architecture

```
┌─────────────────────────────────────┐
│  Web Browser (Port 5800)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  VNC Web Interface                  │
│  (jlesage/baseimage-gui)            │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Antigravity IDE                    │
│  (VSCode + Extensions)              │
│  Running as user: claude (1000)     │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Happy Coder (Background Process)   │
│  AI Development Assistant           │
└─────────────────────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  Workspace: /workspace/{repo}       │
│  Home: /home/claude (RWX PVC)       │
└─────────────────────────────────────┘
```

## Startup Flow

1. **Container starts** - baseimage-gui initializes
2. **init-repo.sh runs**:
   - Checks for `GITHUB_REPO` environment variable
   - Clones repository to `/workspace/{repo-name}` if not exists
   - Configures git credentials with `GITHUB_TOKEN`
   - Starts Happy Coder in background
3. **startapp.sh runs**:
   - Opens Antigravity IDE in the cloned repository
   - Happy Coder is already running and accessible

## Happy Coder Integration

Happy Coder runs as a background service and is accessible within the IDE:

```bash
# Check Happy Coder status
ps aux | grep happy-coder

# View logs
cat /tmp/happy-coder.log

# Restart Happy Coder
sudo -u claude bash -c "cd /workspace/your-repo && happy-coder &"
```

## Local Development

### Run with Docker Compose

```yaml
version: '3.8'
services:
  antigravity:
    build: .
    ports:
      - "5800:5800"
    environment:
      - GITHUB_REPO=https://github.com/yourusername/yourrepo
      - GITHUB_TOKEN=ghp_your_token
      - HAPPY_CODER_API_KEY=your_key
      - VNC_PASSWORD=yourpassword
    volumes:
      - ./home:/home
      - ./workspace:/workspace
```

```bash
docker-compose up
```

### Run with Docker

```bash
docker run -d \
  -p 5800:5800 \
  -e GITHUB_REPO="https://github.com/yourusername/yourrepo" \
  -e GITHUB_TOKEN="ghp_your_token" \
  -e HAPPY_CODER_API_KEY="your_key" \
  -e VNC_PASSWORD="yourpassword" \
  -v $(pwd)/home:/home \
  -v $(pwd)/workspace:/workspace \
  ghcr.io/cpfarhood/antigravity:latest
```

## Kubernetes Deployment

### With Flux

See the animaniacs cluster configuration for GitOps deployment patterns.

### Standalone

```bash
# Apply manifests
kubectl apply -k k8s/

# Check status
kubectl get statefulset antigravity
kubectl get pods -l app=antigravity

# Access logs
kubectl logs antigravity-0

# Access shell
kubectl exec -it antigravity-0 -- bash
```

## Troubleshooting

### Repository not cloning

```bash
# Check logs
kubectl logs antigravity-0 | grep "Repository Initialization"

# Verify GITHUB_REPO is set
kubectl exec antigravity-0 -- env | grep GITHUB

# Check git credentials
kubectl exec antigravity-0 -- cat /home/claude/.git-credentials
```

### Happy Coder not starting

```bash
# Check Happy Coder logs
kubectl exec antigravity-0 -- cat /tmp/happy-coder.log

# Verify API key
kubectl exec antigravity-0 -- env | grep HAPPY_CODER

# Restart Happy Coder
kubectl exec antigravity-0 -- sudo -u claude bash -c "cd /workspace/repo && happy-coder &"
```

### VNC not accessible

```bash
# Check port forwarding
kubectl port-forward antigravity-0 5800:5800

# Verify service
kubectl get svc antigravity

# Check pod status
kubectl describe pod antigravity-0
```

### Permission issues

```bash
# Check ownership
kubectl exec antigravity-0 -- ls -la /home/claude
kubectl exec antigravity-0 -- ls -la /workspace

# Fix ownership
kubectl exec antigravity-0 -- chown -R claude:claude /home/claude
kubectl exec antigravity-0 -- chown -R claude:claude /workspace
```

## Security Considerations

1. **Secrets Management**: Use SealedSecrets or external secret managers
2. **Network Policies**: Restrict ingress/egress as needed
3. **RBAC**: Limit who can access the namespace
4. **VNC Password**: Always set a strong VNC password
5. **GitHub Token**: Use fine-grained tokens with minimal permissions
6. **Container Security**: Runs as non-root user (claude:1000)

## Storage

### Home Directory (`/home`)
- Mounted from ReadWriteMany PVC (`userhome`)
- Persists user settings, credentials, history
- Survives pod restarts

### Workspace (`/workspace`)
- ephemeral emptyDir (can be changed to PVC)
- Contains cloned repository
- Rebuild on pod restart

To persist workspace:
1. Create a PVC for workspace
2. Update `statefulset.yaml` to use PVC instead of emptyDir

## Customization

### Add More Tools

Edit `Dockerfile`:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-package-here \
    && rm -rf /var/lib/apt/lists/*
```

### Change Display Resolution

Set environment variables:

```yaml
env:
  - name: DISPLAY_WIDTH
    value: "2560"
  - name: DISPLAY_HEIGHT
    value: "1440"
```

### Auto-clone Multiple Repos

Modify `init-repo.sh` to support `GITHUB_REPOS` (comma-separated):

```bash
IFS=',' read -ra REPOS <<< "$GITHUB_REPOS"
for repo in "${REPOS[@]}"; do
  # Clone each repo
done
```

## License

MIT

## Credits

- Built on [jlesage/baseimage-gui](https://github.com/jlesage/docker-baseimage-gui)
- Uses [Happy Coder](https://happy.engineering)
- Inspired by Google's Project IDX

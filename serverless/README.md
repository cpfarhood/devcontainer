# DevContainer Serverless 2.0

A serverless, auto-scaling development container platform with dynamic GitHub repository routing, secured by Authentik authentication.

## Architecture Overview

```
User Request: https://devcontainer.farh.net/github/microsoft/vscode
     ↓
Authentik (Authentication & Authorization)
     ↓ (authenticated request with user headers)
NGINX Ingress (SSL termination, rate limiting)
     ↓
Routing Proxy (extracts GitHub repo from URL, adds headers)
     ↓ (with X-GitHub-Repo header)
Knative Service (devcontainer-serverless)
     ↓ (auto-scales from 0 to N instances)
Dev Container Instances (ephemeral, repo-specific)
```

### Key Features

- 🚀 **Scale to Zero**: Containers automatically scale down to zero when not in use
- 🔐 **Authentik Integration**: Full authentication and authorization via Authentik
- 🐙 **Dynamic GitHub Routing**: Access any repo via `/github/{owner}/{repo}`
- ⚡ **Fast Cold Start**: Optimized startup for quick repository access
- 📁 **Built-in File Manager**: Upload/download files via web interface
- 🛠️ **Multiple IDEs**: VSCode, Antigravity, or headless mode
- 🎯 **Per-User Isolation**: Each request gets its own container instance

## Quick Start

### Prerequisites

- Kubernetes cluster with Knative Serving installed
- Authentik deployed and configured
- NGINX Ingress Controller
- cert-manager for SSL certificates

### 1. Deploy the Serverless Components

```bash
# Create namespace and deploy all components
kubectl apply -f serverless/deployment.yaml

# Build and push the routing proxy image
cd serverless/routing-proxy
docker build -t ghcr.io/cpfarhood/devcontainer-routing-proxy:latest .
docker push ghcr.io/cpfarhood/devcontainer-routing-proxy:latest
```

### 2. Configure Authentik

```bash
# Apply Authentik configuration
kubectl apply -f serverless/authentik-config.yaml

# Configure the application via Authentik web UI:
# 1. Go to Applications > Providers > Create
# 2. Type: Forward Auth (single application)
# 3. Name: devcontainer-forward-auth-provider
# 4. External host: https://devcontainer.farh.net
# 5. Create the Application pointing to this provider
```

### 3. Update DNS and SSL

```bash
# Point devcontainer.farh.net to your ingress controller
# The cert-manager will automatically provision SSL certificates
```

### 4. Test the Deployment

```bash
# Visit in browser (will redirect to Authentik for login)
https://devcontainer.farh.net/github/microsoft/vscode

# Check pod scaling
kubectl get pods -n devcontainers -w

# View logs
kubectl logs -n devcontainers deployment/devcontainer-routing-proxy -f
kubectl logs -n devcontainers -l serving.knative.dev/service=devcontainer-serverless -f
```

## Usage

### URL Format

```
https://devcontainer.farh.net/github/{owner}/{repo}
```

### Examples

```bash
# Microsoft VSCode
https://devcontainer.farh.net/github/microsoft/vscode

# Kubernetes
https://devcontainer.farh.net/github/kubernetes/kubernetes

# Your private repo (requires GitHub token)
https://devcontainer.farh.net/github/yourorg/private-repo
```

### Authentication Flow

1. User visits `https://devcontainer.farh.net/github/owner/repo`
2. NGINX Ingress checks with Authentik for authentication
3. If not authenticated, redirects to Authentik login
4. After successful login, request proceeds with user headers
5. Routing proxy extracts repository from URL
6. Knative spins up (or reuses) a container instance
7. Container clones the specified repository and starts IDE

### File Upload/Download

Each container includes a built-in file manager accessible via the VNC web interface:

1. Connect to your dev container via the browser
2. Look for the file manager icon in the VNC toolbar
3. Upload/download files directly through the web interface

## Configuration

### Environment Variables (Secret)

Update the secret in `serverless/deployment.yaml`:

```yaml
stringData:
  GITHUB_TOKEN: "ghp_your_github_token"      # For private repositories
  VNC_PASSWORD: "your_secure_password"       # VNC access password
  ANTHROPIC_API_KEY: "sk-ant-your_key"      # Claude API key
  GIT_USER_NAME: "Your Name"                 # Git commit author
  GIT_USER_EMAIL: "your.email@example.com"  # Git commit email
```

### Scaling Configuration

Modify the Knative Service annotations in `deployment.yaml`:

```yaml
annotations:
  autoscaling.knative.dev/minScale: "0"      # Scale to zero
  autoscaling.knative.dev/maxScale: "20"     # Max instances
  autoscaling.knative.dev/target: "1"        # 1 request per pod
  autoscaling.knative.dev/scale-to-zero-grace-period: "10m"
```

### Resource Limits

Adjust per-instance resources:

```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "8Gi"    # More memory for large repos
    cpu: "4000m"     # More CPU for compilation tasks
```

### IDE Selection

Set the default IDE via environment variable:

```yaml
env:
- name: IDE
  value: "vscode"  # Options: vscode, antigravity, none
```

## Monitoring and Observability

### Health Checks

```bash
# Routing proxy health
curl http://devcontainer-routing-proxy.devcontainers.svc.cluster.local/health

# Knative service status
kn service describe devcontainer-serverless -n devcontainers

# Check container logs
kubectl logs -n devcontainers -l serving.knative.dev/service=devcontainer-serverless -f
```

### Metrics

The setup includes Prometheus integration:

- **Authentik metrics**: User authentication events
- **Knative metrics**: Container scaling, cold starts, request latency
- **NGINX metrics**: Request rates, response times
- **Container metrics**: Resource usage per repository

### Grafana Dashboards

Import the provided dashboard for monitoring:

```bash
# TODO: Create Grafana dashboard JSON
```

## Security Considerations

### Network Policies

```yaml
# Restrict networking between components
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: devcontainer-serverless-network-policy
  namespace: devcontainers
spec:
  podSelector:
    matchLabels:
      serving.knative.dev/service: devcontainer-serverless
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/component: routing-proxy
    ports:
    - protocol: TCP
      port: 5800
  egress:
  - to: []  # Allow all outbound (needed for git clone, package installs)
    ports:
    - protocol: TCP
      port: 443
    - protocol: TCP
      port: 80
```

### Repository Access Control

Configure Authentik policies to control repository access:

```python
# Example Authentik expression policy
github_repo = request.http_request.headers.get('X-GitHub-Repo', '')
user_groups = [g.name for g in request.user.ak_groups.all()]

# Allow admins access to everything
if 'admins' in user_groups:
    return True

# Allow developers access to public repos and specific private repos
if 'developers' in user_groups:
    # Add logic for private repository access based on user attributes
    if 'private-repo-access' in user.ak_attributes:
        allowed_repos = user.ak_attributes['private-repo-access']
        return github_repo in allowed_repos
    return True  # Public repos only

return False
```

## Troubleshooting

### Common Issues

1. **Container won't start**
   ```bash
   # Check Knative service status
   kn service describe devcontainer-serverless -n devcontainers

   # Check pod events
   kubectl describe pod -n devcontainers -l serving.knative.dev/service=devcontainer-serverless
   ```

2. **Repository clone fails**
   ```bash
   # Check GitHub token in secret
   kubectl get secret devcontainer-serverless-secrets -n devcontainers -o yaml

   # Check container logs for git errors
   kubectl logs -n devcontainers -l serving.knative.dev/service=devcontainer-serverless --tail=100
   ```

3. **Authentik authentication loop**
   ```bash
   # Check Authentik outpost logs
   kubectl logs -n authentik -l app.kubernetes.io/name=authentik

   # Verify ingress annotations
   kubectl describe ingress devcontainer-serverless-ingress -n devcontainers
   ```

4. **Slow cold starts**
   ```bash
   # Check container startup time
   kubectl logs -n devcontainers -l serving.knative.dev/service=devcontainer-serverless --timestamps

   # Consider increasing timeout
   # serving.knative.dev/timeoutSeconds: "900"  # 15 minutes
   ```

### Performance Tuning

1. **Reduce cold start time**:
   - Use minimal base image layers
   - Pre-install common development tools
   - Optimize git clone (shallow clone for large repos)

2. **Resource optimization**:
   - Set appropriate resource requests/limits
   - Use `autoscaling.knative.dev/target-utilization-percentage`
   - Consider persistent volumes for frequently accessed repos

3. **Network optimization**:
   - Use private container registry for faster image pulls
   - Configure image pull policies appropriately
   - Consider using a git cache proxy

## Development

### Building the Routing Proxy

```bash
cd serverless/routing-proxy
docker build -t ghcr.io/cpfarhood/devcontainer-routing-proxy:v2.0.0 .
docker push ghcr.io/cpfarhood/devcontainer-routing-proxy:v2.0.0
```

### Testing Locally

```bash
# Run the routing proxy locally
cd serverless/routing-proxy
docker run -p 8080:8080 \
  -e DEVCONTAINER_SERVICE_URL=host.docker.internal:5800 \
  ghcr.io/cpfarhood/devcontainer-routing-proxy:latest

# Test routing
curl -H "X-GitHub-Repo: https://github.com/microsoft/vscode" \
  http://localhost:8080/github/microsoft/vscode
```

### Contributing

1. Create feature branch from `feature/serverless-2.0.0`
2. Make changes to serverless components
3. Test with local Knative setup
4. Submit pull request

## Migration from 1.x

The serverless 2.0 architecture is a complete redesign. Migration steps:

1. **Backup existing data**: Export user configs, git credentials
2. **Deploy 2.0 components**: Following the quick start guide
3. **Migrate users**: Update Authentik with existing user accounts
4. **Test extensively**: Verify repository access and functionality
5. **Switch DNS**: Point domain to new infrastructure
6. **Cleanup 1.x**: Remove old Helm deployments

## Roadmap

- [ ] GitLab support (`/gitlab/group/project`)
- [ ] Bitbucket support
- [ ] Repository templates and scaffolding
- [ ] Collaborative editing features
- [ ] IDE plugins and extensions management
- [ ] Resource quotas per user/group
- [ ] Repository caching and optimization
- [ ] Integration with CI/CD pipelines
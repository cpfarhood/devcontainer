# Deployment Guide

This guide provides step-by-step instructions for deploying the Antigravity Dev Container using Helm.

## Prerequisites

- Kubernetes cluster (1.19+)
- `kubectl` configured to access your cluster
- `helm` CLI installed (3.0+)
- ReadWriteMany storage class available (e.g., `ceph-filesystem`, `nfs-client`, `efs-sc`)
- GitHub Container Registry access (images are public)

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/cpfarhood/devcontainer.git
cd devcontainer
```

### 2. Create Secret (Optional)

For private repos or VNC password:

```bash
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=VNC_PASSWORD='changeme' \
  --from-literal=ANTHROPIC_API_KEY='sk-ant-...'
```

### 3. Deploy with Helm

```bash
# Basic deployment
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo

# With custom storage class
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set storage.className=nfs-client

# With cluster access for kubectl
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set clusterAccess=readwritens
```

### 4. Access the Container

```bash
# Port forward
kubectl port-forward deployment/devcontainer-mydev 5800:5800
open http://localhost:5800
```

## Deployment Options

### Using Values File

Create a custom `values.yaml`:

```yaml
name: mydev
githubRepo: https://github.com/youruser/yourrepo
ide: vscode
ssh: false

# Storage
storage:
  size: 32Gi
  className: ceph-filesystem

# Resources
resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"

# Kubernetes access
clusterAccess: readwritens

# MCP sidecars
mcpSidecars:
  kubernetes:
    enabled: true
  flux:
    enabled: false
```

Deploy:

```bash
helm install mydev ./chart -f values.yaml
```

### SSH Access Setup

Enable SSH and add your public key:

```bash
# Create secret with SSH key
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=SSH_AUTHORIZED_KEYS='ssh-ed25519 AAAA...'

# Deploy with SSH enabled
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set ssh=true

# Connect via SSH
kubectl port-forward deployment/devcontainer-mydev 2222:22
ssh -p 2222 user@localhost
```

### MCP Sidecar Configuration

Control MCP servers for AI-assisted operations.

**Important:** Kubernetes and Flux MCP sidecars are only deployed when:
1. They are enabled in values (`mcpSidecars.<name>.enabled: true`)
2. AND `clusterAccess` is not `none` (they need RBAC permissions to function)

```bash
# Disable all MCP sidecars
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set mcpSidecars.kubernetes.enabled=false \
  --set mcpSidecars.flux.enabled=false \
  --set mcpSidecars.homeassistant.enabled=false

# Enable only Kubernetes MCP
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set mcpSidecars.kubernetes.enabled=true \
  --set mcpSidecars.flux.enabled=false

# Enable Home Assistant MCP (requires credentials)
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=homeassistant-url='http://homeassistant.local:8123' \
  --from-literal=homeassistant-token='your_long_lived_token'

helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set mcpSidecars.homeassistant.enabled=true
```

### Cluster Access Levels

Configure Kubernetes RBAC permissions:

| Value | Scope | Permissions | Use Case |
|-------|-------|-------------|----------|
| `none` | No access | None | Default, isolated development |
| `readonlyns` | Namespace | Read-only | View resources in namespace |
| `readwritens` | Namespace | Full access | Deploy apps in namespace |
| `readonly` | Cluster-wide | Read-only | View all cluster resources |
| `readwrite` | Cluster-wide | Full access | Cluster administration |

```bash
# Example: Full access within namespace
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set clusterAccess=readwritens
```

## Ingress Configuration

### Using Gateway API HTTPRoute

Create an HTTPRoute for external access:

```yaml
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: devcontainer-mydev
spec:
  parentRefs:
  - name: your-gateway
    namespace: your-gateway-namespace
  hostnames:
  - devcontainer.example.com
  rules:
  - backendRefs:
    - name: devcontainer-mydev
      port: 5800
```

### Using Traditional Ingress

Create an Ingress resource:

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: devcontainer-mydev
spec:
  rules:
  - host: devcontainer.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: devcontainer-mydev
            port:
              number: 5800
```

## Advanced Configurations

### Custom Happy Coder Endpoints

For self-hosted Happy instances:

```bash
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set happyServerUrl=https://your-happy-server.com \
  --set happyWebappUrl=https://your-happy-webapp.com
```

### Custom Display Resolution

```bash
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set display.width=2560 \
  --set display.height=1440
```

### Different IDE Options

```bash
# Use Google Antigravity
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set ide=antigravity

# SSH-only mode (no GUI)
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo \
  --set ide=none \
  --set ssh=true
```

## Helm Operations

### List Deployments

```bash
helm list
```

### Upgrade Deployment

```bash
# Change values
helm upgrade mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/newrepo

# Upgrade with new chart version
git pull
helm upgrade mydev ./chart
```

### Uninstall

```bash
helm uninstall mydev

# Note: PVC persists by default
kubectl delete pvc userhome-mydev
```

### Rollback

```bash
# View history
helm history mydev

# Rollback to previous version
helm rollback mydev

# Rollback to specific revision
helm rollback mydev 3
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl get pods -l app.kubernetes.io/instance=mydev

# Describe pod for events
kubectl describe pod -l app.kubernetes.io/instance=mydev

# Check logs
kubectl logs deployment/devcontainer-mydev
```

### Repository Not Cloning

```bash
# Check init logs
kubectl logs deployment/devcontainer-mydev | grep "Repository Initialization"

# Verify secret exists
kubectl get secret devcontainer-mydev-secrets-env

# Check environment
kubectl exec deployment/devcontainer-mydev -- env | grep GITHUB
```

### VNC Not Accessible

```bash
# Check service
kubectl get svc devcontainer-mydev
kubectl describe svc devcontainer-mydev

# Test with port-forward
kubectl port-forward deployment/devcontainer-mydev 5800:5800
```

### MCP Sidecar Issues

```bash
# Check all containers
kubectl get pod -l app.kubernetes.io/instance=mydev -o jsonpath='{.items[0].spec.containers[*].name}'

# Check MCP container logs
kubectl logs deployment/devcontainer-mydev -c kubernetes-mcp
kubectl logs deployment/devcontainer-mydev -c flux-mcp
kubectl logs deployment/devcontainer-mydev -c homeassistant-mcp

# Verify RBAC permissions (for Kubernetes/Flux MCP)
kubectl auth can-i --list --as system:serviceaccount:default:devcontainer-mydev

# Check Home Assistant MCP credentials
kubectl get secret devcontainer-mydev-secrets-env -o jsonpath='{.data.homeassistant-url}' | base64 -d
# Verify the URL is accessible from the pod
kubectl exec deployment/devcontainer-mydev -- curl -s http://homeassistant.local:8123/api/
```

### Storage Issues

```bash
# Check PVC
kubectl get pvc userhome-mydev
kubectl describe pvc userhome-mydev

# Check available storage classes
kubectl get storageclass

# Verify ReadWriteMany support
kubectl get storageclass <class-name> -o yaml | grep -i accessmodes
```

## Best Practices

### Production Deployment

1. **Use specific image tags** instead of `latest`:
   ```bash
   helm install mydev ./chart --set image.tag=v1.0.0
   ```

2. **Set resource limits** appropriately:
   ```yaml
   resources:
     requests:
       memory: "4Gi"
       cpu: "2000m"
     limits:
       memory: "8Gi"
       cpu: "4000m"
   ```

3. **Enable VNC password**:
   ```bash
   kubectl create secret generic devcontainer-mydev-secrets-env \
     --from-literal=VNC_PASSWORD='strong-password-here'
   ```

4. **Use dedicated namespace**:
   ```bash
   kubectl create namespace dev-environments
   helm install mydev ./chart -n dev-environments
   ```

5. **Configure appropriate cluster access**:
   - Use `readonlyns` or `readwritens` for namespace-scoped work
   - Avoid `readwrite` cluster-wide access unless necessary

### Multi-User Deployment

For teams, create separate deployments per user:

```bash
# User 1
helm install alice-dev ./chart \
  --set name=alice-dev \
  --set githubRepo=https://github.com/alice/project

# User 2
helm install bob-dev ./chart \
  --set name=bob-dev \
  --set githubRepo=https://github.com/bob/project
```

### Backup and Recovery

The home directory persists on PVC. To backup:

```bash
# Create backup pod
kubectl run backup --image=busybox --restart=Never --rm -i --tty \
  -- tar czf - -C /home . | gzip > home-backup.tar.gz
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/cpfarhood/devcontainer/issues
- Documentation: https://github.com/cpfarhood/devcontainer
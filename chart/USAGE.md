# Dev Container Helm Chart Usage Guide

This guide provides common usage patterns and examples for the Dev Container Helm chart.

## Quick Start

### 1. Minimal Installation (Recommended)

Use the quickstart values for the simplest setup:

```bash
# Copy and customize quickstart values
cp values-quickstart.yaml my-values.yaml

# Edit my-values.yaml to set your name and repo:
# name: myproject
# githubRepo: https://github.com/youruser/yourproject

# Install
helm install myproject ./chart -f my-values.yaml
```

### 2. One-Command Installation

```bash
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/youruser/yourrepo
```

## Common Use Cases

### Development Environment

**Scenario**: Standard development with GitHub integration

```yaml
name: dev-environment
githubRepo: https://github.com/company/project

ide:
  type: vscode

mcp:
  sidecars:
    kubernetes:
      enabled: true
    playwright:
      enabled: true
    flux:
      enabled: false    # Disable if not using Flux
```

### Team Workspace

**Scenario**: Shared development environment with more resources

```yaml
name: team-workspace
githubRepo: https://github.com/company/project

resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"

storage:
  size: 64Gi

ssh:
  enabled: true         # Enable SSH access for team

clusterAccess: readwrite # Full cluster access
```

### Kubernetes Admin Environment

**Scenario**: Platform engineering with full cluster access

```yaml
name: k8s-admin
githubRepo: https://github.com/company/k8s-configs

clusterAccess: readwrite

mcp:
  sidecars:
    kubernetes:
      enabled: true
    flux:
      enabled: true
    pgtuner:
      enabled: true     # Database administration
    playwright:
      enabled: false    # Save resources
```

### AI/ML Development

**Scenario**: AI development with browser automation

```yaml
name: ai-playground
githubRepo: https://github.com/company/ai-project

resources:
  requests:
    memory: "8Gi"       # More memory for ML workloads
    cpu: "4000m"
  limits:
    memory: "32Gi"
    cpu: "16000m"

storage:
  size: 128Gi           # Large datasets

mcp:
  sidecars:
    playwright:
      enabled: true     # Web scraping, testing
    kubernetes:
      enabled: false    # Save resources
    flux:
      enabled: false
```

### Lightweight Environment

**Scenario**: Resource-constrained setup

```yaml
name: lightweight
githubRepo: https://github.com/youruser/small-project

resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "2Gi"
    cpu: "1000m"

storage:
  size: 8Gi

mcp:
  sidecars:
    kubernetes:
      enabled: false
    flux:
      enabled: false
    playwright:
      enabled: false
    # Only keep essential sidecars enabled
```

## Secret Configuration

### Basic Secrets

```bash
# GitHub access only
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=VNC_PASSWORD='changeme'
```

### Extended Secrets

```bash
# Full feature set
kubectl create secret generic devcontainer-mydev-secrets-env \
  --from-literal=GITHUB_TOKEN='ghp_...' \
  --from-literal=VNC_PASSWORD='changeme' \
  --from-literal=SSH_AUTHORIZED_KEYS='ssh-ed25519 AAAA...' \
  --from-literal=HOMEASSISTANT_URL='http://homeassistant.local:8123' \
  --from-literal=HOMEASSISTANT_TOKEN='eyJ...' \
  --from-literal=DATABASE_URI='postgresql://user:pass@postgres:5432/db'
```

## Storage Configuration

### Different Storage Classes

```yaml
# For different Kubernetes distributions
storage:
  className: ""           # Auto-detect (recommended)
  # className: longhorn   # Longhorn
  # className: nfs-client # NFS
  # className: fast-ssd   # Custom fast storage
```

### Storage Sizes by Use Case

```yaml
# Small projects
storage:
  size: 8Gi

# Standard development
storage:
  size: 32Gi

# Large projects / datasets
storage:
  size: 128Gi

# Team environments
storage:
  size: 256Gi
```

## Access Patterns

### VNC Only (Default)

```yaml
ide:
  type: vscode

# Access via: kubectl port-forward deployment/devcontainer-mydev 5800:5800
```

### SSH Only

```yaml
ide:
  type: none

ssh:
  enabled: true

# Access via: kubectl port-forward deployment/devcontainer-mydev 2222:22
# ssh -p 2222 user@localhost
```

### Both VNC and SSH

```yaml
ide:
  type: vscode

ssh:
  enabled: true

# VNC: kubectl port-forward deployment/devcontainer-mydev 5800:5800
# SSH: kubectl port-forward deployment/devcontainer-mydev 2222:22
```

## Resource Profiles

### Small (1-2 developers)
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "500m"
  limits:
    memory: "4Gi"
    cpu: "2000m"
```

### Medium (standard development)
```yaml
resources:
  requests:
    memory: "2Gi"
    cpu: "1000m"
  limits:
    memory: "8Gi"
    cpu: "4000m"
```

### Large (intensive workloads)
```yaml
resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"
```

### XLarge (AI/ML, data processing)
```yaml
resources:
  requests:
    memory: "8Gi"
    cpu: "4000m"
  limits:
    memory: "32Gi"
    cpu: "16000m"
```

## MCP Sidecar Combinations

### Minimal (basic development)
```yaml
mcp:
  sidecars:
    kubernetes:
      enabled: false
    flux:
      enabled: false
    playwright:
      enabled: true     # Keep for web testing
```

### Standard (full-stack development)
```yaml
mcp:
  sidecars:
    kubernetes:
      enabled: true
    flux:
      enabled: false
    playwright:
      enabled: true
```

### DevOps/Platform (infrastructure work)
```yaml
mcp:
  sidecars:
    kubernetes:
      enabled: true
    flux:
      enabled: true
    pgtuner:
      enabled: true
    playwright:
      enabled: false
```

### All Features
```yaml
mcp:
  sidecars:
    kubernetes:
      enabled: true
    flux:
      enabled: true
    homeassistant:
      enabled: true
    pgtuner:
      enabled: true
    playwright:
      enabled: true
```

## Troubleshooting

### Values Validation

Your IDE should automatically validate values.yaml against the schema. If not:

```bash
# Manual validation (if you have a JSON schema validator)
helm template ./chart -f values.yaml > /dev/null
```

### Common Issues

**Resource Limits**: Start with smaller resource requests and increase as needed.

**Storage Class**: Use `className: ""` for auto-detection.

**GitHub Access**: Ensure GITHUB_TOKEN has `repo` scope.

**MCP Sidecars**: Disable unused sidecars to save resources.

### Getting Help

1. Check the main [README.md](../README.md) for detailed documentation
2. Review [values.yaml](values.yaml) for all available options
3. Use [values-quickstart.yaml](values-quickstart.yaml) as a starting point
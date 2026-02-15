# Deployment Guide

This guide provides step-by-step instructions for deploying the Antigravity Dev Container to Kubernetes.

## Prerequisites

- Kubernetes cluster with Gateway API support
- `kubectl` configured to access your cluster
- ReadWriteMany storage class available (e.g., `ceph-filesystem`, `nfs-client`, `efs-sc`)
- Sealed Secrets controller installed (for secret encryption)
- GitHub Container Registry access (images are public)

## Required Configuration Variables

Before deploying, you need to provide the following configuration:

### 1. Storage Configuration

**Variable:** `storageClassName`
**Location:** `k8s/statefulset.yaml` (line ~117)
**Description:** The ReadWriteMany storage class name in your cluster
**Example values:**
- `ceph-filesystem` (Rook-Ceph)
- `nfs-client` (NFS)
- `efs-sc` (AWS EFS)
- `azurefile` (Azure Files)
- `filestore` (GCP Filestore)

**How to find your storage class:**
```bash
kubectl get storageclass
```

Look for a storage class that supports `ReadWriteMany` access mode.

### 2. GitHub Repository (Required)

**Variable:** `github-repo`
**Location:** `k8s/configmap.yaml` (line ~9)
**Description:** The GitHub repository URL to clone on container startup
**Format:** `https://github.com/username/repository`
**Example:** `https://github.com/cpfarhood/my-project`

### 3. GitHub Token (Optional, for private repos)

**Variable:** `github-token`
**Location:** `k8s/secrets-example.yaml` (sealed secret)
**Description:** GitHub Personal Access Token for cloning private repositories
**Format:** `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
**Required:** Only if cloning a private repository

**How to create a GitHub token:**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Select scopes: `repo` (for private repos)
4. Generate and copy the token

### 4. VNC Password (Optional)

**Variable:** `vnc-password`
**Location:** `k8s/secrets-example.yaml` (sealed secret)
**Description:** Password for accessing the VNC web interface
**Format:** Any string (recommend 12+ characters)
**Required:** Optional, but recommended for security

### 5. Gateway Configuration (Required for external access)

**Variables:**
- `parentRefs.name` - Your Gateway resource name
- `parentRefs.namespace` - Namespace where Gateway is deployed
- `hostnames` - Domain name for accessing the container

**Location:** `k8s/httproute.yaml`
**Example:**
```yaml
parentRefs:
- name: cilium-gateway  # Your Gateway name
  namespace: kube-system  # Your Gateway namespace
hostnames:
- "devcontainer.example.com"  # Your domain
```

### 6. Namespace (Optional)

**Variable:** `namespace`
**Location:** `k8s/kustomization.yaml` (line ~5)
**Description:** Kubernetes namespace to deploy into
**Default:** `default`
**Example:** `devcontainer`, `development`, `team-workspaces`

### 7. Container Image (Optional)

**Variable:** `image`
**Location:** `k8s/statefulset.yaml` (line ~32)
**Description:** Docker image to use
**Default:** `ghcr.io/cpfarhood/devcontainer:latest`
**Format:** `registry/repository:tag`

### 8. Resource Limits (Optional)

**Variables:**
- `resources.requests.memory` (default: `2Gi`)
- `resources.requests.cpu` (default: `1000m`)
- `resources.limits.memory` (default: `8Gi`)
- `resources.limits.cpu` (default: `4000m`)

**Location:** `k8s/statefulset.yaml` (lines ~98-103)

### 9. Happy Coder Configuration (Optional)

**Variables:**
- `happy-server-url` - Custom Happy server URL
- `happy-webapp-url` - Custom Happy webapp URL

**Location:** `k8s/configmap.yaml` (lines ~12-13, commented out)
**Default:** Uses Happy's default servers
**When to set:** Only if using a self-hosted Happy instance

## Deployment Steps

### Step 1: Clone the Repository

```bash
git clone https://github.com/cpfarhood/devcontainer.git
cd devcontainer
```

### Step 2: Configure Storage Class

Edit `k8s/statefulset.yaml` and find the `volumeClaimTemplates` section (around line 117):

```bash
# Find your storage class
kubectl get storageclass

# Edit the file
vi k8s/statefulset.yaml
```

Change `storageClassName` to match your cluster:
```yaml
volumeClaimTemplates:
- metadata:
    name: userhome
  spec:
    accessModes: [ "ReadWriteMany" ]
    storageClassName: "ceph-filesystem"  # ← Change this
    resources:
      requests:
        storage: 10Gi
```

### Step 3: Configure GitHub Repository

Edit `k8s/configmap.yaml`:

```bash
vi k8s/configmap.yaml
```

Set your repository URL:
```yaml
data:
  github-repo: "https://github.com/yourusername/yourrepo"
```

### Step 4: Configure Gateway (HTTPRoute)

Edit `k8s/httproute.yaml`:

```bash
# Find your Gateway
kubectl get gateway -A

# Edit the file
vi k8s/httproute.yaml
```

Update with your Gateway details:
```yaml
spec:
  parentRefs:
  - name: your-gateway-name        # ← Change this
    namespace: your-gateway-namespace  # ← Change this
  hostnames:
  - "devcontainer.yourdomain.com"  # ← Change this
```

### Step 5: Create Secrets

Create the secrets for GitHub token and VNC password:

```bash
# Create the secret
kubectl create secret generic antigravity-secrets \
  --from-literal=github-token='ghp_your_token_here' \
  --from-literal=vnc-password='your_vnc_password' \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml > k8s/sealedsecrets.yaml

# Verify the sealed secret was created
cat k8s/sealedsecrets.yaml
```

**If you don't have Sealed Secrets controller:**

Option 1: Install Sealed Secrets
```bash
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml
```

Option 2: Use plain secrets (not recommended for production)
```bash
kubectl create secret generic antigravity-secrets \
  --from-literal=github-token='ghp_your_token_here' \
  --from-literal=vnc-password='your_vnc_password'
```

### Step 6: Review Configuration (Optional)

Review and adjust optional settings:

**Namespace:**
```bash
vi k8s/kustomization.yaml
# Change line 5: namespace: default
```

**Resource limits:**
```bash
vi k8s/statefulset.yaml
# Adjust lines 98-103 for your needs
```

### Step 7: Deploy to Kubernetes

```bash
# Deploy everything
kubectl apply -k k8s/

# Or if you changed the namespace
kubectl apply -k k8s/ -n your-namespace
```

### Step 8: Verify Deployment

```bash
# Check StatefulSet
kubectl get statefulset antigravity

# Check Pod
kubectl get pods -l app=antigravity

# Check PVC
kubectl get pvc -l app=antigravity

# Check HTTPRoute
kubectl get httproute antigravity

# View logs
kubectl logs antigravity-0
```

### Step 9: Access the Container

**Option A: Via HTTPRoute (external access)**
```bash
# Open in browser
open https://devcontainer.yourdomain.com
```

**Option B: Via Port Forward (local access)**
```bash
# Port forward to localhost
kubectl port-forward statefulset/antigravity 5800:5800

# Open in browser
open http://localhost:5800
```

## Configuration Summary

Here's a quick checklist of all variables you need to set:

### Required Variables

| Variable | File | Line | Example Value |
|----------|------|------|---------------|
| `storageClassName` | `k8s/statefulset.yaml` | ~117 | `ceph-filesystem` |
| `github-repo` | `k8s/configmap.yaml` | ~9 | `https://github.com/user/repo` |
| `parentRefs.name` | `k8s/httproute.yaml` | ~8 | `cilium-gateway` |
| `parentRefs.namespace` | `k8s/httproute.yaml` | ~9 | `kube-system` |
| `hostnames` | `k8s/httproute.yaml` | ~10 | `devcontainer.example.com` |

### Optional Variables

| Variable | File | Line | Default | When to Change |
|----------|------|------|---------|----------------|
| `namespace` | `k8s/kustomization.yaml` | ~5 | `default` | If deploying to different namespace |
| `github-token` | Sealed secret | N/A | None | For private repos |
| `vnc-password` | Sealed secret | N/A | None | For VNC security |
| `image` | `k8s/statefulset.yaml` | ~32 | `ghcr.io/cpfarhood/devcontainer:latest` | For specific version or custom build |
| `resources.*` | `k8s/statefulset.yaml` | ~98-103 | 2Gi/8Gi RAM, 1/4 CPU | Based on workload needs |
| `happy-server-url` | `k8s/configmap.yaml` | ~12 | Default Happy server | For self-hosted Happy |
| `happy-webapp-url` | `k8s/configmap.yaml` | ~13 | Default Happy webapp | For self-hosted Happy |

## Troubleshooting

### Pod not starting

**Check events:**
```bash
kubectl describe pod antigravity-0
```

**Common issues:**
- Storage class doesn't support ReadWriteMany
- PVC not binding (check storage class exists)
- Image pull errors (check image name)

### Repository not cloning

**Check logs:**
```bash
kubectl logs antigravity-0 | grep -A 10 "Repository Initialization"
```

**Common issues:**
- Invalid GitHub URL
- Private repo without token
- Token doesn't have correct permissions

### HTTPRoute not working

**Check HTTPRoute:**
```bash
kubectl describe httproute antigravity
```

**Common issues:**
- Gateway name/namespace incorrect
- Domain not pointing to Gateway
- TLS certificate not issued

### VNC not accessible

**Check service:**
```bash
kubectl get svc antigravity
kubectl describe svc antigravity
```

**Port forward test:**
```bash
kubectl port-forward antigravity-0 5800:5800
# Try accessing http://localhost:5800
```

## Quick Deploy Example

Complete deployment with all values filled in:

```bash
# 1. Set your values
STORAGE_CLASS="ceph-filesystem"
GITHUB_REPO="https://github.com/myuser/myproject"
GITHUB_TOKEN="ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
VNC_PASSWORD="my-secure-password-123"
GATEWAY_NAME="cilium-gateway"
GATEWAY_NAMESPACE="kube-system"
DOMAIN="devcontainer.example.com"

# 2. Update storage class
sed -i "s/storageClassName: .*/storageClassName: \"$STORAGE_CLASS\"/" k8s/statefulset.yaml

# 3. Update GitHub repo
sed -i "s|github-repo: .*|github-repo: \"$GITHUB_REPO\"|" k8s/configmap.yaml

# 4. Update Gateway
sed -i "s/- name: gateway/- name: $GATEWAY_NAME/" k8s/httproute.yaml
sed -i "s/namespace: gateway-system/namespace: $GATEWAY_NAMESPACE/" k8s/httproute.yaml
sed -i "s/antigravity.example.com/$DOMAIN/" k8s/httproute.yaml

# 5. Create sealed secret
kubectl create secret generic antigravity-secrets \
  --from-literal=github-token="$GITHUB_TOKEN" \
  --from-literal=vnc-password="$VNC_PASSWORD" \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml > k8s/sealedsecrets.yaml

# 6. Deploy
kubectl apply -k k8s/

# 7. Watch deployment
kubectl get pods -l app=antigravity -w
```

## Updates and Maintenance

### Updating the Image

The image is automatically built and pushed to ghcr.io on every commit to main.

**To use latest:**
```bash
kubectl set image statefulset/antigravity \
  antigravity=ghcr.io/cpfarhood/devcontainer:latest
```

**To use specific version:**
```bash
kubectl set image statefulset/antigravity \
  antigravity=ghcr.io/cpfarhood/devcontainer:v1.0.0
```

### Changing Repository

Edit the ConfigMap and restart:
```bash
kubectl edit configmap antigravity-config
# Change github-repo value
kubectl rollout restart statefulset/antigravity
```

### Scaling

```bash
# Scale to multiple instances (each gets own home PVC)
kubectl scale statefulset antigravity --replicas=3
```

## Support

For issues or questions:
- GitHub Issues: https://github.com/cpfarhood/devcontainer/issues
- Documentation: https://github.com/cpfarhood/devcontainer

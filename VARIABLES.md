# Configuration Variables Reference

Quick reference for all configurable variables in this project.

## Required Variables

These MUST be configured before deployment:

### Storage Class Name
- **Variable:** `storageClassName`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~117
- **Type:** String
- **Description:** ReadWriteMany storage class available in your cluster
- **Example:** `ceph-filesystem`, `nfs-client`, `efs-sc`
- **How to find:** `kubectl get storageclass`

### GitHub Repository URL
- **Variable:** `github-repo`
- **File:** `k8s/configmap.yaml`
- **Line:** ~9
- **Type:** String (URL)
- **Description:** Repository to clone on container startup
- **Format:** `https://github.com/username/repository`
- **Example:** `https://github.com/cpfarhood/my-project`

### Gateway Name
- **Variable:** `parentRefs[0].name`
- **File:** `k8s/httproute.yaml`
- **Line:** ~8
- **Type:** String
- **Description:** Name of your Gateway resource
- **How to find:** `kubectl get gateway -A`

### Gateway Namespace
- **Variable:** `parentRefs[0].namespace`
- **File:** `k8s/httproute.yaml`
- **Line:** ~9
- **Type:** String
- **Description:** Namespace where Gateway is deployed
- **How to find:** `kubectl get gateway -A`

### Domain Hostname
- **Variable:** `hostnames[0]`
- **File:** `k8s/httproute.yaml`
- **Line:** ~11
- **Type:** String (FQDN)
- **Description:** Domain name for accessing the container
- **Example:** `devcontainer.example.com`

## Optional Variables

### GitHub Token
- **Variable:** `github-token`
- **File:** Sealed Secret
- **Type:** String (GitHub PAT)
- **Description:** Personal Access Token for private repos
- **Required:** Only for private repositories
- **Format:** `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`
- **Scopes:** `repo`

### Anthropic API Key
- **Variable:** `ANTHROPIC_API_KEY`
- **File:** Kubernetes Secret (referenced by `envSecretName`)
- **Type:** String (Anthropic API key)
- **Description:** API key for Claude Code / Happy Coder authentication. Browser-based OAuth login does not work inside the VNC session, so this key is **required** for Happy Coder to function.
- **Required:** Yes (for Happy Coder / Claude Code)
- **Format:** `sk-ant-api03-...`
- **How to get:** https://console.anthropic.com/settings/keys

### VNC Password
- **Variable:** `vnc-password`
- **File:** Kubernetes Secret (referenced by `envSecretName`)
- **Type:** String
- **Description:** Password for VNC web interface
- **Required:** Recommended for security
- **Format:** Any string (12+ characters recommended)

### Namespace
- **Variable:** `namespace`
- **File:** `k8s/kustomization.yaml`
- **Line:** ~5
- **Type:** String
- **Description:** Kubernetes namespace for deployment
- **Default:** `default`

### Container Image
- **Variable:** `image`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~32
- **Type:** String (image reference)
- **Description:** Docker image to deploy
- **Default:** `ghcr.io/cpfarhood/devcontainer:latest`
- **Format:** `registry/repository:tag`

### Memory Request
- **Variable:** `resources.requests.memory`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~99
- **Type:** String (quantity)
- **Description:** Minimum memory to reserve
- **Default:** `2Gi`
- **Format:** `<number>Gi` or `<number>Mi`

### Memory Limit
- **Variable:** `resources.limits.memory`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~102
- **Type:** String (quantity)
- **Description:** Maximum memory allowed
- **Default:** `8Gi`
- **Format:** `<number>Gi` or `<number>Mi`

### CPU Request
- **Variable:** `resources.requests.cpu`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~100
- **Type:** String (quantity)
- **Description:** Minimum CPU to reserve
- **Default:** `1000m` (1 core)
- **Format:** `<number>m` (millicores) or `<number>` (cores)

### CPU Limit
- **Variable:** `resources.limits.cpu`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~103
- **Type:** String (quantity)
- **Description:** Maximum CPU allowed
- **Default:** `4000m` (4 cores)
- **Format:** `<number>m` (millicores) or `<number>` (cores)

### Storage Size
- **Variable:** `storage` (under volumeClaimTemplates)
- **File:** `k8s/statefulset.yaml`
- **Line:** ~120
- **Type:** String (quantity)
- **Description:** Size of home directory PVC
- **Default:** `10Gi`
- **Format:** `<number>Gi` or `<number>Ti`

### Happy Server URL
- **Variable:** `happy-server-url`
- **File:** `k8s/configmap.yaml`
- **Line:** ~12 (commented)
- **Type:** String (URL)
- **Description:** Custom Happy Coder server
- **Default:** `https://api.cluster-fluster.com`
- **When to set:** Self-hosted Happy instance only

### Happy Webapp URL
- **Variable:** `happy-webapp-url`
- **File:** `k8s/configmap.yaml`
- **Line:** ~13 (commented)
- **Type:** String (URL)
- **Description:** Custom Happy Coder webapp
- **Default:** `https://app.happy.engineering`
- **When to set:** Self-hosted Happy instance only

### Display Width
- **Variable:** `DISPLAY_WIDTH`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~56
- **Type:** String (number)
- **Description:** VNC display width in pixels
- **Default:** `1920`

### Display Height
- **Variable:** `DISPLAY_HEIGHT`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~58
- **Type:** String (number)
- **Description:** VNC display height in pixels
- **Default:** `1080`

### User ID
- **Variable:** `USER_ID`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~51
- **Type:** String (number)
- **Description:** UID for claude user
- **Default:** `1000`

### Group ID
- **Variable:** `GROUP_ID`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~53
- **Type:** String (number)
- **Description:** GID for claude user
- **Default:** `1000`

### StatefulSet Replicas
- **Variable:** `replicas`
- **File:** `k8s/statefulset.yaml`
- **Line:** ~21
- **Type:** Integer
- **Description:** Number of container instances
- **Default:** `1`
- **Note:** Each replica gets own home PVC

## Environment Variables (Runtime)

These are set at runtime, not in configuration files:

### GITHUB_REPO
- **Type:** String (URL)
- **Description:** Repository URL (from ConfigMap)
- **Required:** Yes
- **Source:** ConfigMap `antigravity.github-repo`

### GITHUB_TOKEN
- **Type:** String
- **Description:** GitHub PAT (from Secret)
- **Required:** No (only for private repos)
- **Source:** Secret `antigravity.github-token`

### VNC_PASSWORD
- **Type:** String
- **Description:** VNC password (from Secret)
- **Required:** No
- **Source:** Secret `antigravity.vnc-password`

### HAPPY_SERVER_URL
- **Type:** String (URL)
- **Description:** Happy server URL (from ConfigMap)
- **Required:** No
- **Source:** ConfigMap `antigravity.happy-server-url`

### HAPPY_WEBAPP_URL
- **Type:** String (URL)
- **Description:** Happy webapp URL (from ConfigMap)
- **Required:** No
- **Source:** ConfigMap `antigravity.happy-webapp-url`

### HAPPY_HOME_DIR
- **Type:** String (path)
- **Description:** Happy data directory
- **Required:** No
- **Default:** `/home/claude/.happy`
- **Source:** Hardcoded in StatefulSet

### HAPPY_EXPERIMENTAL
- **Type:** String (boolean)
- **Description:** Enable Happy experimental features
- **Required:** No
- **Default:** `true`
- **Source:** Hardcoded in StatefulSet

## Variable Groups by Use Case

### Minimal Deployment
Only these variables are required for basic deployment:
1. `storageClassName`
2. `github-repo`
3. `parentRefs.name`
4. `parentRefs.namespace`
5. `hostnames`

### Private Repository Deployment
Add these for private repos:
1. All minimal deployment variables
2. `github-token` (sealed secret)

### Production Deployment
Recommended for production:
1. All private repository variables
2. `vnc-password` (sealed secret)
3. `resources.requests.*` (adjusted for workload)
4. `resources.limits.*` (adjusted for workload)
5. `namespace` (dedicated namespace)

### Multi-User Deployment
For multiple users:
1. All production deployment variables
2. `replicas` (set to number of users)
3. Larger `storage` size for home PVCs

## Quick Copy Templates

### Minimal Required Variables
```yaml
# k8s/statefulset.yaml
storageClassName: "CHANGE_ME"  # Line ~117

# k8s/configmap.yaml
github-repo: "CHANGE_ME"  # Line ~9

# k8s/httproute.yaml
parentRefs:
- name: CHANGE_ME  # Line ~8
  namespace: CHANGE_ME  # Line ~9
hostnames:
- "CHANGE_ME"  # Line ~11
```

### With Secrets
```bash
kubectl create secret generic antigravity-secrets \
  --from-literal=GITHUB_TOKEN='CHANGE_ME' \
  --from-literal=VNC_PASSWORD='CHANGE_ME' \
  --from-literal=ANTHROPIC_API_KEY='sk-ant-api03-...' \
  --dry-run=client -o yaml | \
  kubeseal --format=yaml > k8s/sealedsecrets.yaml
```

### With Resource Adjustments
```yaml
# k8s/statefulset.yaml (lines ~98-103)
resources:
  requests:
    memory: "CHANGE_ME"  # e.g., 4Gi
    cpu: "CHANGE_ME"     # e.g., 2000m
  limits:
    memory: "CHANGE_ME"  # e.g., 16Gi
    cpu: "CHANGE_ME"     # e.g., 8000m
```

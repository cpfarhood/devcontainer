# Helm Chart Values Reference

Complete reference for all configurable values in the Antigravity Dev Container Helm chart.

## Core Configuration

### name
- **Type:** String
- **Default:** `""`
- **Required:** Yes
- **Description:** Instance name used to generate resource names (`devcontainer-{name}`, `userhome-{name}`)
- **Example:** `mydev`, `alice-dev`, `team-workspace`

### githubRepo
- **Type:** String
- **Default:** `""`
- **Required:** Yes
- **Description:** GitHub repository URL to clone into `/workspace`
- **Example:** `https://github.com/username/repository`

### ide
- **Type:** String
- **Default:** `vscode`
- **Options:** `vscode`, `antigravity`, `none`
- **Description:** IDE to launch inside the container
  - `vscode` — VSCode via VNC browser UI on port 5800
  - `antigravity` — Google Antigravity (VSCode fork) via VNC on port 5800
  - `none` — No IDE; useful when `ssh: true` is the sole access method

### ssh
- **Type:** Boolean
- **Default:** `false`
- **Description:** Start an OpenSSH server on port 22 in addition to the IDE
- **Note:** Requires `SSH_AUTHORIZED_KEYS` in env secret for key-based login

## Image Configuration

### image.repository
- **Type:** String
- **Default:** `ghcr.io/cpfarhood/devcontainer`
- **Description:** Container image repository

### image.tag
- **Type:** String
- **Default:** `latest`
- **Description:** Container image tag
- **Best Practice:** Use specific version tags for production

### image.pullPolicy
- **Type:** String
- **Default:** `Always`
- **Options:** `Always`, `IfNotPresent`, `Never`
- **Description:** Image pull policy

## Happy Coder Configuration

### happyServerUrl
- **Type:** String
- **Default:** `https://happy.farh.net`
- **Description:** Happy Coder server endpoint
- **When to Change:** Self-hosted Happy instance

### happyWebappUrl
- **Type:** String
- **Default:** `https://happy-coder.farh.net`
- **Description:** Happy Coder webapp URL
- **When to Change:** Self-hosted Happy instance

### happyHomeDir
- **Type:** String
- **Default:** `/config/userdata/.happy`
- **Description:** Happy runtime state directory (persists on PVC)

### happyExperimental
- **Type:** String
- **Default:** `"true"`
- **Description:** Enable experimental Happy features

## Display Configuration

### display.width
- **Type:** String
- **Default:** `"1920"`
- **Description:** VNC display width in pixels

### display.height
- **Type:** String
- **Default:** `"1080"`
- **Description:** VNC display height in pixels

### secureConnection
- **Type:** String
- **Default:** `"0"`
- **Options:** `"0"`, `"1"`
- **Description:** Set to `"0"` when TLS is terminated at the gateway layer

## User Configuration

### userId
- **Type:** String
- **Default:** `"1000"`
- **Description:** UID for the app user

### groupId
- **Type:** String
- **Default:** `"1000"`
- **Description:** GID for the app user

## Storage Configuration

### storage.size
- **Type:** String
- **Default:** `32Gi`
- **Description:** Size of the persistent home directory
- **Format:** Kubernetes quantity (e.g., `10Gi`, `100Gi`, `1Ti`)

### storage.className
- **Type:** String
- **Default:** `ceph-filesystem`
- **Description:** StorageClass name (must support ReadWriteMany)
- **Examples:** `ceph-filesystem`, `nfs-client`, `efs-sc`, `azurefile`

### shm.sizeLimit
- **Type:** String
- **Default:** `2Gi`
- **Description:** `/dev/shm` size (memory-backed emptyDir for Electron apps)

## Resource Limits

### resources.requests.memory
- **Type:** String
- **Default:** `2Gi`
- **Description:** Minimum memory to reserve
- **Format:** Kubernetes quantity

### resources.requests.cpu
- **Type:** String
- **Default:** `1000m`
- **Description:** Minimum CPU to reserve
- **Format:** Millicores (`1000m` = 1 CPU core)

### resources.limits.memory
- **Type:** String
- **Default:** `8Gi`
- **Description:** Maximum memory allowed
- **Format:** Kubernetes quantity

### resources.limits.cpu
- **Type:** String
- **Default:** `4000m`
- **Description:** Maximum CPU allowed
- **Format:** Millicores (`4000m` = 4 CPU cores)

## Kubernetes Access

### clusterAccess
- **Type:** String
- **Default:** `none`
- **Options:**
  - `none` — No cluster access
  - `readonlyns` — Read-only access to release namespace
  - `readwritens` — Full access to release namespace
  - `readonly` — Read-only access cluster-wide
  - `readwrite` — Full access cluster-wide
- **Description:** RBAC permissions for the pod's ServiceAccount

## Secrets

### envSecretName
- **Type:** String
- **Default:** `""` (auto-generates as `devcontainer-{name}-secrets-env`)
- **Description:** Name of existing Secret containing environment variables
- **Keys Recognized:**
  - `GITHUB_TOKEN` — PAT for private repo access
  - `VNC_PASSWORD` — Password for VNC web UI
  - `ANTHROPIC_API_KEY` — API key for Claude
  - `SSH_AUTHORIZED_KEYS` — Public keys for SSH access
  - `homeassistant-url` — Home Assistant base URL (e.g., http://homeassistant.local:8123)
  - `homeassistant-token` — Home Assistant long-lived access token

## MCP Sidecars

### mcpSidecars.kubernetes.enabled
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enable Kubernetes MCP server sidecar

### mcpSidecars.kubernetes.image.repository
- **Type:** String
- **Default:** `quay.io/containers/kubernetes_mcp_server`
- **Description:** Kubernetes MCP server image

### mcpSidecars.kubernetes.image.tag
- **Type:** String
- **Default:** `latest`
- **Description:** Kubernetes MCP server image tag

### mcpSidecars.kubernetes.port
- **Type:** Integer
- **Default:** `8080`
- **Description:** Port for Kubernetes MCP server

### mcpSidecars.kubernetes.resources
- **Type:** Object
- **Default:**
  ```yaml
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
  ```
- **Description:** Resource limits for Kubernetes MCP sidecar

### mcpSidecars.flux.enabled
- **Type:** Boolean
- **Default:** `true`
- **Description:** Enable Flux MCP server sidecar

### mcpSidecars.flux.image.repository
- **Type:** String
- **Default:** `ghcr.io/controlplaneio-fluxcd/flux-operator-mcp`
- **Description:** Flux MCP server image

### mcpSidecars.flux.image.tag
- **Type:** String
- **Default:** `v0.41.1`
- **Description:** Flux MCP server image tag

### mcpSidecars.flux.port
- **Type:** Integer
- **Default:** `8081`
- **Description:** Port for Flux MCP server

### mcpSidecars.flux.resources
- **Type:** Object
- **Default:**
  ```yaml
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
  ```
- **Description:** Resource limits for Flux MCP sidecar

### mcpSidecars.homeassistant.enabled
- **Type:** Boolean
- **Default:** `false`
- **Description:** Enable Home Assistant MCP server sidecar
- **Note:** Requires `homeassistant-url` and `homeassistant-token` in env secret

### mcpSidecars.homeassistant.image.repository
- **Type:** String
- **Default:** `ghcr.io/homeassistant-ai/ha-mcp`
- **Description:** Home Assistant MCP server image

### mcpSidecars.homeassistant.image.tag
- **Type:** String
- **Default:** `stable`
- **Description:** Home Assistant MCP server image tag
- **Options:** `stable` (recommended), `latest` (dev builds), `v{version}` (specific version)

### mcpSidecars.homeassistant.port
- **Type:** Integer
- **Default:** `8087`
- **Description:** Port for Home Assistant MCP server (SSE mode)

### mcpSidecars.homeassistant.resources
- **Type:** Object
- **Default:**
  ```yaml
  requests:
    memory: "64Mi"
    cpu: "50m"
  limits:
    memory: "256Mi"
    cpu: "500m"
  ```
- **Description:** Resource limits for Home Assistant MCP sidecar

## Usage Examples

### Minimal Configuration

```yaml
name: mydev
githubRepo: https://github.com/user/repo
```

### Production Configuration

```yaml
name: prod-workspace
githubRepo: https://github.com/company/application
ide: vscode
ssh: true

image:
  tag: v1.0.0

storage:
  size: 100Gi
  className: ceph-filesystem

resources:
  requests:
    memory: "4Gi"
    cpu: "2000m"
  limits:
    memory: "16Gi"
    cpu: "8000m"

clusterAccess: readwritens

mcpSidecars:
  kubernetes:
    enabled: true
  flux:
    enabled: false
```

### Development Team Configuration

```yaml
name: team-dev
githubRepo: https://github.com/team/project
ide: antigravity

display:
  width: "2560"
  height: "1440"

storage:
  size: 50Gi
  className: nfs-client

clusterAccess: readonly

happyServerUrl: https://happy.internal.company.com
happyWebappUrl: https://happy-app.internal.company.com
```

### Smart Home Development Configuration

```yaml
name: smarthome-dev
githubRepo: https://github.com/user/home-automation
ide: vscode

clusterAccess: readwritens

mcpSidecars:
  kubernetes:
    enabled: true
  flux:
    enabled: false
  homeassistant:
    enabled: true
    image:
      tag: stable

# Requires secrets:
# homeassistant-url: http://homeassistant.local:8123
# homeassistant-token: <long-lived-access-token>
```

## Helm CLI Examples

### Using --set Flags

```bash
# Basic deployment
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/user/repo

# With multiple values
helm install mydev ./chart \
  --set name=mydev \
  --set githubRepo=https://github.com/user/repo \
  --set ide=antigravity \
  --set storage.size=50Gi \
  --set clusterAccess=readwritens \
  --set mcpSidecars.flux.enabled=false
```

### Using Values File

Create `custom-values.yaml`:
```yaml
name: mydev
githubRepo: https://github.com/user/repo
storage:
  size: 50Gi
clusterAccess: readwritens
```

Deploy:
```bash
helm install mydev ./chart -f custom-values.yaml
```

### Combining Methods

```bash
helm install mydev ./chart \
  -f base-values.yaml \
  -f prod-values.yaml \
  --set githubRepo=https://github.com/user/repo \
  --set image.tag=v2.0.0
```

## Value Precedence

Values are applied in order of precedence (highest to lowest):
1. `--set` flags on command line
2. `-f` values files (later files override earlier)
3. `chart/values.yaml` defaults

## Environment Variables

These environment variables are set in the container based on chart values:

| Environment Variable | Source Value | Description |
|---------------------|--------------|-------------|
| `GITHUB_REPO` | `githubRepo` | Repository to clone |
| `GITHUB_TOKEN` | Secret: `github-token` | PAT for private repos |
| `VNC_PASSWORD` | Secret: `vnc-password` | VNC access password |
| `ANTHROPIC_API_KEY` | Secret: `anthropic-api-key` | Claude API key |
| `SSH_AUTHORIZED_KEYS` | Secret: `ssh-authorized-keys` | SSH public keys |
| `HAPPY_SERVER_URL` | `happyServerUrl` | Happy server endpoint |
| `HAPPY_WEBAPP_URL` | `happyWebappUrl` | Happy webapp URL |
| `HAPPY_HOME_DIR` | `happyHomeDir` | Happy data directory |
| `HAPPY_EXPERIMENTAL` | `happyExperimental` | Experimental features |
| `DISPLAY_WIDTH` | `display.width` | VNC width |
| `DISPLAY_HEIGHT` | `display.height` | VNC height |
| `SECURE_CONNECTION` | `secureConnection` | TLS termination |
| `USER_ID` | `userId` | App user UID |
| `GROUP_ID` | `groupId` | App user GID |
| `IDE` | `ide` | IDE to launch |
| `SSH` | `ssh` | SSH server enabled |
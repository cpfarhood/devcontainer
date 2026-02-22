{{/*
Resource name prefix: devcontainer-{name}
*/}}
{{- define "antigravity.fullname" -}}
{{- printf "devcontainer-%s" .Values.name }}
{{- end }}

{{/*
PVC name: userhome-{name}
*/}}
{{- define "antigravity.pvcName" -}}
{{- printf "userhome-%s" .Values.name }}
{{- end }}

{{/*
Secret name for env vars, default to devcontainer-{name}-secrets-env
*/}}
{{- define "antigravity.envSecretName" -}}
{{- .Values.envSecretName | default (printf "devcontainer-%s-secrets-env" .Values.name) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "antigravity.labels" -}}
app: devcontainer
instance: {{ .Values.name }}
{{- end }}

{{/*
Smart resource sizing based on enabled features
*/}}
{{- define "antigravity.smartResources" -}}
{{- $baseMemory := "2Gi" }}
{{- $baseCpu := "1000m" }}
{{- $limitMemory := "8Gi" }}
{{- $limitCpu := "4000m" }}

{{/* Adjust for enabled MCP sidecars */}}
{{- if .Values.mcp.sidecars.playwright.enabled }}
  {{- $baseMemory = "3Gi" }}
  {{- $limitMemory = "12Gi" }}
{{- end }}

{{/* Adjust for IDE type */}}
{{- if eq .Values.ide.type "antigravity" }}
  {{- $baseMemory = "4Gi" }}
  {{- $limitMemory = "16Gi" }}
{{- end }}

requests:
  memory: {{ .Values.resources.requests.memory | default $baseMemory | quote }}
  cpu: {{ .Values.resources.requests.cpu | default $baseCpu | quote }}
limits:
  memory: {{ .Values.resources.limits.memory | default $limitMemory | quote }}
  cpu: {{ .Values.resources.limits.cpu | default $limitCpu | quote }}
{{- end }}

{{/*
Auto-detect environment type and set smart defaults
*/}}
{{- define "antigravity.smartDefaults" -}}
{{- $isDev := or (contains "dev" .Values.name) (contains "test" .Values.name) (contains "local" .Values.name) }}
{{- $isProd := or (contains "prod" .Values.name) (contains "production" .Values.name) }}
{{- $isTeam := or (contains "team" .Values.name) (contains "shared" .Values.name) }}

{{/* Development environment - enable more sidecars, smaller resources */}}
{{- if $isDev }}
development: true
{{/* Production environment - conservative defaults, fewer sidecars */}}
{{- else if $isProd }}
production: true
{{/* Team environment - enable SSH, more resources */}}
{{- else if $isTeam }}
team: true
{{- end }}
{{- end }}

{{/*
Smart MCP sidecar selection based on cluster access
*/}}
{{- define "antigravity.mcpDefaults" -}}
{{- if eq .Values.clusterAccess "none" }}
  {{/* No cluster access - disable k8s/flux sidecars */}}
  kubernetes:
    enabled: false
  flux:
    enabled: false
{{- else }}
  {{/* Has cluster access - enable k8s sidecars */}}
  kubernetes:
    enabled: true
  flux:
    enabled: {{ ne .Values.clusterAccess "readonly" }}
{{- end }}
{{- end }}

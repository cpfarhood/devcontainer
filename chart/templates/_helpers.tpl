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

{{/*
Name
*/}}
{{- define "connected-registry.name" -}}
{{- .Chart.Name }}
{{- end }}

{{/*
Connected Registry Service Name
*/}}
{{- define "connected-registry.service-name" -}}
  {{- if  .Values.connectionString -}}
    {{- $connectedregistryname := .Values.connectionString | toString | regexFind "ConnectedRegistryName=.*;SyncTokenName=" -}}
    {{- if $connectedregistryname -}}
      {{- $connectedregistryname | trimPrefix "ConnectedRegistryName=" | trimSuffix ";SyncTokenName=" -}}
    {{- else -}}
      {{ required "The connectionString format is invalid" "" }}
    {{- end }}
  {{- else -}}
    {{ required "The connectionString value must be provided" "" }}
  {{- end }}
{{- end }}

{{/*
Connection String
*/}}
{{- define "connected-registry.connection-string-secret-name" -}}
{{- printf "%s-%s" .Chart.Name "connection-string" }}
{{- end }}

{{/*
TLS Secret Name
*/}}
{{- define "connected-registry.tls-secret-name" -}}
{{- printf "%s-%s" .Chart.Name "tls" }}
{{- end }}

{{/*
PVC Name
*/}}
{{- define "connected-registry.pvc-name" -}}
{{- printf "%s-%s" .Chart.Name "pvc" }}
{{- end }}

{{/*
Namespace
*/}}
{{- define "connected-registry.namespace" -}}
{{- .Release.Namespace }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "connected-registry.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "connected-registry.labels" -}}
helm.sh/chart: {{ include "connected-registry.chart" . }}
{{ include "connected-registry.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "connected-registry.selectorLabels" -}}
app.kubernetes.io/name: "connected-registry"
{{- end }}

{{/*
TLS type
*/}}
{{- define "connected-registry.tlsType" -}}
  {{- if not .Values.httpEnabled }}
    {{- if (and .Values.tls.secret (and (not .Values.tls.crt) (not .Values.tls.key))) -}}
      secret
    {{- else if (and (and .Values.tls.crt .Values.tls.key) (not .Values.tls.secret )) -}}
      certificateKeyPair
    {{- else if (and (not .Values.tls.secret) (and (not .Values.tls.crt) (not .Values.tls.key))) -}}
      {{ required "when httpEnabled is false, the name of tls secret must be provided (tls.secret) or a certificate key pair must be provided (tls.crt and tls.key)" ""}}
    {{- else if (and .Values.tls.secret (or .Values.tls.crt .Values.tls.key)) -}}
      {{ required "the name of tls secret may be provided (tls.secret) or a certificate key pair may be provided (tls.crt and tls.key), not both" ""}}
    {{- else -}}
      {{ required "when providing a certificate key pair, both tls.crt and tls.key must be provided" ""}}
    {{- end }}
  {{- end }}
{{- end }}
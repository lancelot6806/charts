{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "ntppool.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "ntppool.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ntppool.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "ntppool.chartLabels" -}}
helm.sh/chart: {{ include "ntppool.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- define "ntppool.labels" -}}
{{ include "ntppool.chartLabels" . }}
{{ include "ntppool.selectorLabels" . }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "ntppool.selectorLabels" -}}
app.kubernetes.io/name: {{ include "ntppool.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: {{ include "ntppool.name" . }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "ntppool.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "ntppool.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Standard app container
*/}}
{{- define "ntppool.appContainerDefaults" -}}
securityContext:
  {{- toYaml .Values.securityContext | nindent 2 }}
image: "{{ .Values.image.repository }}:{{ .Chart.AppVersion }}"
imagePullPolicy: {{ .Values.image.pullPolicy }}
env:
- name: CBCONFIG
  value: /var/ntppool/combust.conf
# - name: config-md5
#   value: 0c20892bb6878df5ce68ba9d1ea2550a
- name: auth0_secret
  valueFrom:
    secretKeyRef:
      key: auth0_secret
      name: {{ include "ntppool.fullname" . }}-secrets
- name: db_pass
  valueFrom:
    secretKeyRef:
      key: db_pass
      name: {{ include "ntppool.fullname" . }}-secrets
- name: account_id_key
  valueFrom:
    secretKeyRef:
      key: account_id_key
      name: {{ include "ntppool.fullname" . }}-secrets
- name: geoip_service
  value: {{ .Release.Name }}-geoip
- name: splash_service
  value: {{ .Release.Name }}-splash
- name: smtp_service
  value: {{ .Release.Name }}-smtp
envFrom:
- configMapRef:
    name: {{ include "ntppool.fullname" . }}-config
volumeMounts:
- mountPath: /ntppool/data
  name: data
{{ if and .Values.develPath (eq .Values.config.deployment_mode "devel") -}}
- mountPath: '/ntppool'
  name: 'code'
{{- end -}}
{{- end -}}

{{- define "ntppool.appVolumes" -}}
{{ $values := .Values }}
- emptyDir: {}
  name: data
{{ if (and $values.develPath (eq $values.config.deployment_mode "devel")) }}
- name: code
  hostPath:
    path: {{ $values.develPath }}
{{- end}}
{{- end -}}
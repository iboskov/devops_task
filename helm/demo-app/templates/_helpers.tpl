{{/*
Common labels
*/}}
{{- define "demo-app.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Frontend labels
*/}}
{{- define "demo-app.frontend.labels" -}}
{{ include "demo-app.labels" . }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend labels
*/}}
{{- define "demo-app.backend.labels" -}}
{{ include "demo-app.labels" . }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Postgres labels
*/}}
{{- define "demo-app.postgres.labels" -}}
{{ include "demo-app.labels" . }}
app.kubernetes.io/component: postgres
{{- end }}

{{/*
Frontend selector labels
*/}}
{{- define "demo-app.frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: frontend
{{- end }}

{{/*
Backend selector labels
*/}}
{{- define "demo-app.backend.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: backend
{{- end }}

{{/*
Postgres selector labels
*/}}
{{- define "demo-app.postgres.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: postgres
{{- end }}

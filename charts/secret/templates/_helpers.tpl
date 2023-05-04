{{/*
Create a default fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- if ne .Chart.Name "base" }}
{{- default (printf "%s" .Release.Name) .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

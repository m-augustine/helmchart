{{/*
Create a default fully qualified app name.
*/}}
{{- define "app.fullname" -}}
{{- if ne .Chart.Name "base" }}
{{- default (printf "%s-%s" .Release.Name .Chart.Name) .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "app.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "app.labels" -}}
helm.sh/chart: {{ include "app.chart" . }}
{{ include "app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}


{{/*
Selector labels
*/}}
{{- define "app.selectorLabels" -}}
app.kubernetes.io/fullName: {{ include "app.fullname" . }}
app.kubernetes.io/releaseName: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "app.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "app.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}


{{/*
Render a template container if the requested or the normal container config

.
  Values -- Config at the global scope
  ... -- the rest of the top level builtin objcets
  pod -- Config at the pod scope
  container -- Config at the container scope
*/}}
{{- define "app.container" -}}
{{- if .container.template -}}
  {{- $fileName := print "containers/" .container.template ".yaml" -}}
  {{- $fileText := .Files.Get $fileName -}}
  {{- if not $fileText -}}
    {{- print "invalid template " $fileName | fail -}}
  {{- end -}}
  {{- $templateDict := (tpl $fileText . | fromYaml) -}}
  {{- if $templateDict.Error -}}
    {{- print "template container produced invalid YAML: " $fileName "\n" $fileText | fail -}}
  {{- end -}}
  {{- include "app.container" (merge (dict "container" $templateDict) (omit $ "container")) -}}
{{- else -}}
name: {{ .container.name }}
{{- if .Values.podSecurityContext }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- end }}
image: {{ .container.image.repository }}:{{ .container.image.tag | default "latest" }}
imagePullPolicy: {{ .container.image.pullPolicy }}
command:
{{- end }}
{{- range .container.command }}
  - {{ . }}
{{- end }}
args:
{{- range .container.args }}
  - {{ . }}
{{- end }}
{{- if .container.ports }}
ports:
  {{- toYaml .container.ports | nindent 2 }}
{{- end }}
{{- if .container.startupProbe }}
startupProbe:
  {{- toYaml .container.startupProbe | nindent 2 }}
{{- end }}
{{- if .container.livenessProbe }}
livenessProbe:
  {{- toYaml .container.livenessProbe | nindent 2 }}
{{- end }}
{{- if .container.readinessProbe }}
readinessProbe:
  {{- toYaml .container.readinessProbe | nindent 2 }}
{{- end }}
{{- if .container.resources }}
resources:
  {{- toYaml .container.resources | nindent 2 }}
{{- end }}
volumeMounts:
{{- if .container.volumeMounts }}
  {{- toYaml .container.volumeMounts | nindent 2 }}
{{- end }}
  {{- range .Values.additionalVolumes }}
  - name: {{ .name }}
    mountPath: {{ .mountPath }}
    readOnly: {{ .readOnly }}
  {{- end }}
envFrom:
  - configMapRef:
      name: {{ include "app.fullname" $ }}
  - secretRef:
      name: {{ include "app.fullname" $ }}
env:
{{- if .container.envVars }}
  {{- toYaml .container.envVars | nindent 2 }}
{{- end }}
{{- if .container.resources }}
resources:
  {{- toYaml .container.resources | nindent 2 }}
{{- end }}
{{- end }}


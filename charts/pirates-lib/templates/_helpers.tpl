{{- define "pirates-lib.fullname" -}}
{{- .Release.Name -}}
{{- end -}}

{{- define "pirates-lib.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "pirates-lib.labels" -}}
{{ include "pirates-lib.selectorLabels" . }}
app.kubernetes.io/part-of: pirates-mlflowops
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "pirates-lib.job" -}}
apiVersion: batch/v1
kind: Job
metadata:
  name: {{ include "pirates-lib.fullname" . }}
  labels:
    {{- include "pirates-lib.labels" . | nindent 4 }}
spec:
  backoffLimit: {{ .Values.backoffLimit | default 3 }}
  ttlSecondsAfterFinished: {{ .Values.ttlSecondsAfterFinished | default 86400 }}
  template:
    metadata:
      labels:
        {{- include "pirates-lib.selectorLabels" . | nindent 8 }}
    spec:
      restartPolicy: Never
      {{- if .Values.spot.enabled }}
      nodeSelector:
        pirates/workload: training
      tolerations:
        - key: pirates/training
          operator: Equal
          value: "true"
          effect: NoSchedule
      {{- end }}
      containers:
        - name: {{ .Chart.Name }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          command: ["sh", "-c"]
          args:
            - {{ .Values.script | quote }}
          {{- with .Values.env }}
          env:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- with .Values.resources }}
          resources:
            {{- toYaml . | nindent 12 }}
          {{- end }}
{{- end -}}

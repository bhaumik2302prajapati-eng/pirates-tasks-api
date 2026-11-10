{{- define "pirates-lib.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "pirates-lib.fullname" . }}
  labels:
    {{- include "pirates-lib.labels" . | nindent 4 }}
spec:
  type: {{ .Values.service.type | default "ClusterIP" }}
  ports:
    - name: {{ .Values.service.portName | default "http" }}
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    {{- include "pirates-lib.selectorLabels" . | nindent 4 }}
{{- end -}}

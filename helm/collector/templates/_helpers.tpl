{{/*
Pod template spec - shared between DaemonSet and Deployment
*/}}
{{- define "collector.podTemplate" -}}
metadata:
  labels:
    app.kubernetes.io/name: collector
    app.kubernetes.io/instance: {{ .Release.Name }}
{{- range $key, $value := .Values.podLabels }}
    {{ $key }}: {{ $value }}
{{- end }}
spec:
  containers:
  - name: collector
    image: {{ .Values.image.repository }}:{{ .Values.image.tag }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    {{- if .Values.extraArgs }}
    args:
      {{- toYaml .Values.extraArgs | nindent 6 }}
    {{- end }}
    {{- if or .Values.extraEnvs .Values.secret.otlpEndpoint .Values.secret.licenseKey .Values.scenarioTag .Values.serviceName }}
    env:
      {{- if .Values.secret.otlpEndpoint }}
      - name: OTEL_EXPORTER_OTLP_ENDPOINT
        valueFrom:
          secretKeyRef:
            name: {{ .Release.Name }}-collector-secret
            key: otlp-endpoint
      {{- end }}
      {{- if .Values.secret.licenseKey }}
      - name: NEW_RELIC_LICENSE_KEY
        valueFrom:
          secretKeyRef:
            name: {{ .Release.Name }}-collector-secret
            key: license-key
      {{- end }}
      {{- if .Values.scenarioTag }}
      - name: SCENARIO_TAG
        value: {{ .Values.scenarioTag | quote }}
      {{- end }}
      {{- if .Values.serviceName }}
      - name: SERVICE_NAME
        value: {{ .Values.serviceName | quote }}
      {{- end }}
      {{- if .Values.extraEnvs }}
      {{- toYaml .Values.extraEnvs | nindent 6 }}
      {{- end }}
    {{- end }}
    {{- if .Values.resources }}
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    {{- end }}
    volumeMounts:
    - name: config
      mountPath: /etc/otelcol/config.yaml
      subPath: config.yaml
      readOnly: true
    {{- if .Values.extraVolumeMounts }}
    {{- toYaml .Values.extraVolumeMounts | nindent 4 }}
    {{- end }}
  volumes:
  - name: config
    configMap:
      name: {{ .Values.configMap.existingName }}
      items:
      - key: {{ .Values.configMap.key }}
        path: config.yaml
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
{{- end }}

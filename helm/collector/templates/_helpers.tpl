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
  {{- range $signal, $config := .Values.telemetrygen.signals }}
  {{- $config = $config | default dict }}
  - name: telemetrygen-{{ $signal }}
    image: {{ $.Values.telemetrygen.image.repository }}:{{ $.Values.telemetrygen.image.tag }}
    imagePullPolicy: {{ $.Values.telemetrygen.image.pullPolicy }}
    args:
    - {{ $signal }}
    {{- if eq ($config.protocol | default "http") "grpc" }}
    - --otlp-endpoint=localhost:4317
    {{- else }}
    - --otlp-http
    - --otlp-endpoint=localhost:4318
    {{- end }}
    {{- if or (not (hasKey $config "insecure")) $config.insecure }}
    - --otlp-insecure
    {{- end }}
    - --otlp-attributes=service.name="telemetrygen-{{ $signal }}"
    - --rate=10
    - --duration=5m
    {{- if eq $signal "logs" }}
    - "--body=short log"
    {{- end }}
    {{- if $config.extraArgs }}
    {{- toYaml $config.extraArgs | nindent 4 }}
    {{- end }}
  {{- end }}
  {{- if .Values.weaver.registry.existingName }}
  {{- $liveCheck := .Values.weaver.liveCheck | default dict }}
  - name: weaver
    image: {{ .Values.weaver.image.repository }}:{{ .Values.weaver.image.tag }}
    imagePullPolicy: {{ .Values.weaver.image.pullPolicy }}
    args:
    - registry
    - live-check
    - --registry=/registry
    {{- with .Values.weaver.registry.configKey }}
    - --config=/registry/{{ . }}
    {{- end }}
    - --format={{ $liveCheck.format | default "json" }}
    - --output={{ $liveCheck.output | default "http" }}
    - --otlp-grpc-address=127.0.0.1
    - --otlp-grpc-port={{ $liveCheck.otlpGrpcPort | default 5123 }}
    - --admin-port={{ $liveCheck.adminPort | default 4320 }}
    - --inactivity-timeout={{ $liveCheck.inactivityTimeout | default 0 }}
    {{- if $liveCheck.extraArgs }}
    {{- toYaml $liveCheck.extraArgs | nindent 4 }}
    {{- end }}
    ports:
    - name: weaver-otlp
      containerPort: {{ $liveCheck.otlpGrpcPort | default 5123 }}
    - name: weaver-admin
      containerPort: {{ $liveCheck.adminPort | default 4320 }}
    volumeMounts:
    - name: weaver-registry
      mountPath: /registry
      readOnly: true
  {{- end }}
  volumes:
  - name: config
    configMap:
      name: {{ .Values.configMap.existingName }}
      items:
      - key: {{ .Values.configMap.key }}
        path: config.yaml
  {{- if .Values.weaver.registry.existingName }}
  - name: weaver-registry
    configMap:
      name: {{ .Values.weaver.registry.existingName }}
  {{- end }}
  {{- if .Values.extraVolumes }}
  {{- toYaml .Values.extraVolumes | nindent 2 }}
  {{- end }}
{{- end }}

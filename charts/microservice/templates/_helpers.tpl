{{apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: coolcinema-microservices
  namespace: argocd
spec:
  # Включаем Go Templates для поддержки функций (toJson)
  goTemplate: true
  
  generators:
    - git:
        repoURL: https://github.com/coolcinema/core.git
        revision: main
        files:
          - path: "packages/contracts/apps/*.json"

  template:
    metadata:
      # Имя приложения = имя файла без расширения
      # При goTemplate: true нужна точка перед path!
      name: "{{.path.filenameNormalized}}"
    spec:
      project: default
      source:
        repoURL: https://github.com/coolcinema/infra-k8s.git
        targetRevision: main
        path: charts/microservice

        helm:
          # Передаем распаршенные данные в Helm Values.
          values: |
            fullnameOverride: "{{.fullnameOverride}}"
            image:
              repository: "{{.image.repository}}"
            service:
              ports: {{.service.ports | toJson}}
            ingress: {{.ingress | toJson}}
            env: {{.env | toJson}}

      destination:
        server: https://kubernetes.default.svc
        namespace: coolcinema

      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true/* Expand the name of the chart. */}}
{{- define "microservice.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create a default fully qualified app name. */}}
{{- define "microservice.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.22"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "loki_stack" {
  name       = "loki-stack"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.2"

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  set {
    name  = "promtail.lokiServiceName"
    value = "loki-stack"
  }

  set {
    name  = "promtail.config.scrape_configs[0].job_name"
    value = "kubernetes-pods"
  }

  set {
    name  = "promtail.config.scrape_configs[0].kubernetes_sd_configs[0].role"
    value = "pod"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].source_labels[0]"
    value = "__meta_kubernetes_pod_label_app"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].action"
    value = "keep"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].regex"
    value = ".*"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[1].source_labels[0]"
    value = "__meta_kubernetes_namespace"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[1].target_label"
    value = "namespace"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[2].source_labels[0]"
    value = "__meta_kubernetes_pod_name"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[2].target_label"
    value = "pod"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[3].source_labels[0]"
    value = "__meta_kubernetes_pod_container_name"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[3].target_label"
    value = "container"
  }

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "grafana.sidecar.datasources.enabled"
    value = "false"
  }

  set {
    name  = "loki.tolerations[0].key"
    value = "kubernetes.io/arch"
  }
  set {
    name  = "loki.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "loki.tolerations[0].value"
    value = "arm64"
  }
  set {
    name  = "loki.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "promtail.tolerations[0].key"
    value = "kubernetes.io/arch"
  }
  set {
    name  = "promtail.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "promtail.tolerations[0].value"
    value = "arm64"
  }
  set {
    name  = "promtail.tolerations[0].effect"
    value = "NoSchedule"
  }
}

resource "grafana_data_source" "loki" {
  type = "loki"
  name = "Loki"
  url = "http://loki-stack.monitoring.svc.cluster.local:3100"
  access_mode = "proxy"
  is_default = false
  uid = "loki"
}

resource "helm_release" "grafana" {
  name       = "grafana"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  version    = var.grafana_version

  set {
    name  = "adminUser"
    value = "admin"
  }

  set {
    name  = "adminPassword"
    value = var.grafana_sa_token
  }

  set {
    name  = "service.type"
    value = "ClusterIP"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = "5Gi"
  }

  set {
    name  = "grafana.ini.auth.anonymous.enabled"
    value = "false"
  }

  set {
    name  = "tolerations[0].key"
    value = "kubernetes.io/arch"
  }
  set {
    name  = "tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "tolerations[0].value"
    value = "arm64"
  }
  set {
    name  = "tolerations[0].effect"
    value = "NoSchedule"
  }
}

resource "kubernetes_manifest" "grafana_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "grafana-gateway"
      namespace = "monitoring"
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          tls = {
            mode           = "SIMPLE"
            credentialName = var.wildcard_tls_secret
          }
          hosts = ["grafana.complyt.cloud"]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "virtualservice_grafana" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = "grafana"
      namespace = kubernetes_namespace.monitoring.metadata[0].name
    }
    spec = {
      hosts    = ["grafana.complyt.cloud"]
      gateways = ["monitoring/grafana-gateway"]
      http = [
        {
          match = [
            {
              uri = {
                prefix = "/"
              }
            },
          ]
          route = [
            {
              destination = {
                host = "grafana.monitoring.svc.cluster.local"
                port = {
                  number = 80
                }
              }
            },
          ]
        },
      ]
    }
  }
}

resource "grafana_dashboard" "app_logs_per_namespace" {
  config_json = jsonencode({
    title         = "Application Logs per Namespace"
    uid           = "logs-per-apps"
    schemaVersion = 30
    version       = 1
    refresh       = "10s"
    panels = flatten([
      for idx, app in tolist(values(var.apps)) : {
        title      = "Logs: ${app.namespace}"
        type       = "logs"
        datasource = "Loki"
        gridPos = {
          h = 8
          w = 24
          x = 0
          y = idx * 8
        }
        targets = [
          {
            expr       = "{namespace=\"${app.namespace}\"}"
            datasource = "Loki"
          }
        ]
      }
    ])
  })
}

resource "grafana_dashboard" "istio_envoy_access_logs" {
  config_json = jsonencode({
    title         = "Istio Envoy Access Logs"
    uid           = "istio-envoy-logs"
    schemaVersion = 30
    version       = 1
    refresh       = "10s"
    panels        = [
      {
        title  = "Envoy Access Logs"
        type   = "logs"
        gridPos = {
          h = 8
          w = 24
          x = 0
          y = 0
        }
        targets = [
          {
            expr        = "{job=~\"istio-ingressgateway.+\"}"
            datasource  = "Loki"
          }
        ]
      }
    ]
  })
}

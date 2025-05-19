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
          hosts = ["grafana-internal.complyt.io"]
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
      hosts    = ["grafana-internal.complyt.io"]
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
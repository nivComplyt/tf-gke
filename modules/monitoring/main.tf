resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

resource "helm_release" "loki" {
  name       = "loki"
  chart      = "loki"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "6.20.0"

  values = [
    yamlencode({
      deploymentMode = "SingleBinary"

      singleBinary = {
        replicas = 1
      }

      write = {
        replicas = 0
      }
      read = {
        replicas = 0
      }
      backend = {
        replicas = 0
      }

      gateway = {
        enabled = false
      }
      chunksCache = {
        enabled = false
      }
      resultsCache = {
        enabled = false
      }

      loki = {
        auth_enabled = false
        useTestSchema = true

        storage = {
          type = "filesystem"
          bucketNames = {
            chunks = "unused"
            ruler  = "unused"
            admin  = "unused"
          }
        }

        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
      }

      lokiCanary = {
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
      }

      singleBinary = {
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
      }

      tolerations = [
        {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      ]
    })
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  chart      = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version    = "8.13.1"

  values = [
    yamlencode({
      adminPassword = var.grafana_admin_password
      datasources = {
        "datasources.yaml" = {
          apiVersion = 1
          datasources = [
            {
              name      = "Loki"
              type      = "loki"
              access    = "proxy"
              url       = "http://loki.monitoring.svc.cluster.local:3100"
              isDefault = true
            }
          ]
        }
      }
      tolerations = [
        {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      ]
    })
  ]
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
                host = "${helm_release.grafana.name}.${kubernetes_namespace.monitoring.metadata[0].name}.svc.cluster.local"
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

resource "kubernetes_manifest" "authorization_policy_grafana" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "allow-only-vpn"
      namespace = "monitoring"
    }
    spec = {
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "grafana"
        }
      }
      action = "ALLOW"
      rules = [
        {
          from = [
            {
              source = {
                ipBlocks = var.vpn_ip_block
              }
            }
          ]
        }
      ]
    }
  }
}

# resource "helm_release" "tempo" {
#   name       = "tempo"
#   chart      = "tempo"
#   repository = "https://grafana.github.io/helm-charts"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   version    = "1.21.0"
# }
# 
# resource "helm_release" "mimir" {
#   name       = "mimir"
#   chart      = "mimir-distributed"
#   repository = "https://grafana.github.io/helm-charts"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   version    = "5.7.0"
# }
# 
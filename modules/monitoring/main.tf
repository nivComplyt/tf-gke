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
# 
# resource "google_storage_bucket" "loki" {
#   name     = var.bucket_name
#   location = var.region
# 
#   uniform_bucket_level_access = true
#   force_destroy               = true
# 
#   versioning {
#     enabled = true
#   }
#   lifecycle_rule {
#     action {
#       type = "Delete"
#     }
#     condition {
#       age = 90
#     }
#   }
# }
# 
# resource "google_service_account" "loki" {
#   account_id   = "loki-storage-access"
#   display_name = "Loki Storage Access"
# }
# 
# resource "google_storage_bucket_iam_member" "loki_writer" {
#   bucket = google_storage_bucket.loki.name
#   role   = "roles/storage.objectAdmin"
#   member = "serviceAccount:${google_service_account.loki.email}"
# }
# 
# resource "google_storage_bucket_iam_binding" "loki_public" {
#   bucket = google_storage_bucket.loki.name
#   role   = "roles/storage.objectViewer"
# 
#   members = [
#     "allUsers",
#   ]
# }
# 
# resource "helm_release" "loki" {
#   name       = "loki"
#   chart      = "loki"
#   repository = "https://grafana.github.io/helm-charts"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   version    = "6.20.0"
# 
#   disable_openapi_validation = true
#   skip_crds                  = true
# 
#   values = [
#     yamlencode({
#       deploymentMode = "SimpleScalable<->Distributed"
#       replication_factor = 3
# 
#       ingester = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#         persistence = {
#           enabled = false
#         }
#       }
# 
#       distributor = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       querier = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       queryFrontend = {
#         replicas = 2
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       queryScheduler = {
#         replicas = 2
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       compactor = {
#         enabled = true
#         retention_enabled = true
#         shared_store = true
#         tolerations = var.arm64_tolerations
#       }
# 
#       indexGateway = {
#         enabled = true
#         replicas = 2
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#         extraTolerations = var.arm64_tolerations
#         extraAffinity = {
#           nodeAffinity = {
#             requiredDuringSchedulingIgnoredDuringExecution = {
#               nodeSelectorTerms = [
#                 {
#                   matchExpressions = [
#                     {
#                       key      = "kubernetes.io/arch"
#                       operator = "In"
#                       values   = ["arm64"]
#                     }
#                   ]
#                 }
#               ]
#             }
#           }
#         }
#         extraNodeSelector = {
#           "kubernetes.io/arch" = "arm64"
#         }
#       }
# 
#       backend = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       read = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       write = {
#         replicas = 3
#         maxUnavailable = 1
#         tolerations = var.arm64_tolerations
#       }
# 
#       gateway = {
#         enabled = true
#         tolerations = var.arm64_tolerations
#       }
# 
#       chunksCache = {
#         enabled = true
#         tolerations = var.arm64_tolerations
#       }
# 
#       resultsCache = {
#         enabled = true
#         tolerations = var.arm64_tolerations
#       }
# 
#       loki = {
#         auth_enabled = false
#         useTestSchema = false
# 
#         schemaConfig = {
#           configs = [
#             {
#               from         = "2025-05-05"
#               store        = "tsdb"
#               object_store = "gcs"
#               schema       = "v13"
#               index = {
#                 prefix = "index_"
#                 period = "24h"
#               }
#             }
#           ]
#         }
# 
#         limits_config = {
#           retention_period            = "168h"
#           allow_structured_metadata   = true
#           max_query_lookback           = "0s"
#         }
# 
#         storage = {
#           bucketNames = {
#             chunks = google_storage_bucket.loki.name
#             ruler  = google_storage_bucket.loki.name
#             admin  = google_storage_bucket.loki.name
#           }
#           type = "gcs"
#         }
# 
#         storage_config = {
#           gcs = {
#             bucket_name = google_storage_bucket.loki.name
#           }
#           tsdb_shipper = {
#             active_index_directory = "/var/loki/index"
#             cache_location         = "/var/loki/index_cache"
#           }
#         }
# 
#         chunk_store_config = {
#           max_look_back_period = "0s"
#         }
# 
#         table_manager = {
#           retention_deletes_enabled = true
#           retention_period          = "168h"
#         }
# 
#         memberlistConfig      = null
#         extraMemberlistConfig = null
#       }
# 
#       lokiCanary = {
#         enabled = false
#       }
# 
#       test = {
#         enabled = false
#       }
#     })
#   ]
# }
# 
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

  # set {
  #   name  = "grafana.tolerations[0].key"
  #   value = "kubernetes.io/arch"
  # }
  # set {
  #   name  = "grafana.tolerations[0].operator"
  #   value = "Equal"
  # }
  # set {
  #   name  = "grafana.tolerations[0].value"
  #   value = "arm64"
  # }
  # set {
  #   name  = "grafana.tolerations[0].effect"
  #   value = "NoSchedule"
  # }
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
  version    = "8.13.1"

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

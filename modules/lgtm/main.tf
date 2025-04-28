# resource "kubernetes_namespace" "monitoring" {
#   metadata {
#     name = "monitoring"
#   }
# }
# 
# resource "helm_release" "loki" {
#   name       = "loki"
#   chart      = "loki"
#   repository = "https://grafana.github.io/helm-charts"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   version    = "6.20.0"
# 
#   values = [
#     yamlencode({
#       loki = {
#         storage = {
#           bucketNames = {
#             chunks = "loki-chunks" # Replace with your chunk store bucket name (e.g., S3 bucket)
#             index = "loki-index"   # Replace with your index store bucket name (e.g., S3 bucket)
#           }
#           backend = "s3" # Or "gcs", "filesystem", etc.
#           s3 = { # Configure S3 if you're using it
#             bucket = "your-s3-bucket-name"
#             region = "your-aws-region"
#             # Add other S3 configuration as needed (access_key_id, secret_access_key, etc.)
#           }
#           # Add configuration for other backends if you're using them (gcs, filesystem)
#         }
#       }
#       promtail = {
#         enabled = true
#         config = {
#           snippets = {
#             kubernetes = {
#               pipelineStages = [
#                 { json = { expressions = "<.>=" } },
#                 { timestamp = { source = "time", format = "RFC3339Nano" } },
#                 { labels = { job = "kubernetes.container", pod = "{{.pod_name}}", namespace = "{{.pod_namespace}}", container = "{{.container_name}}" } },
#                 { relabeling = [{ sourceLabels = ["__meta_kubernetes_pod_node_name"], targetLabel = "node" }] }
#               ]
#             }
#           }
#         }
#       }
#     })
#   ]
# }
# 
# resource "helm_release" "grafana" {
#   name       = "grafana"
#   chart      = "grafana"
#   repository = "https://grafana.github.io/helm-charts"
#   namespace  = kubernetes_namespace.monitoring.metadata[0].name
#   version    = "8.13.1"
# 
#   values = [
#     yamlencode({
#       adminPassword = "admin"
#       service = {
#         type = "LoadBalancer"
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
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
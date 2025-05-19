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

# resource "grafana_dashboard" "istio_envoy_access_logs" {
#   config_json = jsonencode({
#     title         = "Istio Envoy Access Logs"
#     uid           = "istio-envoy-logs"
#     schemaVersion = 30
#     version       = 1
#     refresh       = "10s"
#     panels        = [
#       {
#         title  = "Envoy Access Logs"
#         type   = "logs"
#         gridPos = {
#           h = 8
#           w = 24
#           x = 0
#           y = 0
#         }
#         targets = [
#           {
#             expr        = "{job=~\"istio-ingressgateway.+\"}"
#             datasource  = "Loki"
#           }
#         ]
#       }
#     ]
#   })
# }

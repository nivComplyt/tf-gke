# terraform {
#   required_providers {
#     kubernetes = {
#       source  = "hashicorp/kubernetes"
#       version = "~> 2.36"
#     }
#   }
# }
# 
# resource "kubernetes_secret" "dockerhub_regcred" {
#   metadata {
#     name      = "regcred"
#     namespace = kubernetes_namespace.analytics.metadata[0].name
#   }
# 
#   type = "kubernetes.io/dockerconfigjson"
# 
#   data = {
#     ".dockerconfigjson" = base64encode(jsonencode({
#       auths = {
#         "https://index.docker.io/v1/" = {
#           username = var.docker_username
#           password = var.docker_password
#           auth     = base64encode("${var.docker_username}:${var.docker_password}")
#         }
#       }
#     }))
#   }
# }
# 
# resource "kubernetes_secret" "tls" {
#   metadata {
#     name      = "analytics-ss-tls"
#     namespace = "analytics"
#   }
# 
#   type = "kubernetes.io/tls"
# 
#   data = {
#     "tls.crt" = var.tls_cert
#     "tls.key" = var.tls_key
#   }
# }
# 
# resource "kubernetes_namespace" "analytics" {
#   metadata {
#     name = "analytics"
#     labels = {
#       "istio-injection" = "enabled"
#     }
#   }
# }
# 
# resource "kubernetes_deployment" "analytics_app" {
#   metadata {
#     name      = "analytics-app"
#     namespace = kubernetes_namespace.analytics.metadata[0].name
#     labels = {
#       app = "analytics-app"
#     }
#   }
# 
#   spec {
#     replicas = var.replicas
# 
#     selector {
#       match_labels = {
#         app = "analytics-app"
#       }
#     }
# 
#     template {
#       metadata {
#         labels = {
#           app = "analytics-app"
#         }
#       }
# 
#       spec {
#         container {
#           name  = "analytics"
#           image = var.image
# 
#           port {
#             container_port = var.port
#           }
# 
#           resources {
#             requests = {
#               cpu    = "5"
#               memory = "8Gi"
#             }
#             limits = {
#               cpu    = "5"
#               memory = "8Gi"
#             }
#           }
#         }
# 
#         image_pull_secrets {
#           name = kubernetes_secret.dockerhub_regcred.metadata[0].name
#         }
# 
#         toleration {
#           key      = "kubernetes.io/arch"
#           operator = "Equal"
#           value    = "arm64"
#           effect   = "NoSchedule"
#         }
#       }
#     }
#   }
# }
# 
# resource "kubernetes_service" "analytics_svc" {
#   metadata {
#     name      = "analytics-service"
#     namespace = kubernetes_namespace.analytics.metadata[0].name
#   }
# 
#   spec {
#     selector = {
#       app = "analytics-app"
#     }
# 
#     port {
#       protocol    = "TCP"
#       port        = 80
#       target_port = var.port
#     }
#   }
# }
# 
# resource "kubernetes_manifest" "istio_gateway" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1"
#     kind       = "Gateway"
#     metadata = {
#       name      = "analytics-gateway"
#       namespace = "analytics"
#     }
#     spec = {
#       selector = {
#         istio = "ingressgateway"
#       }
#       servers = [{
#         port = {
#           number   = 443
#           name     = "https"
#           protocol = "HTTPS"
#         }
#         tls = {
#           mode           = "SIMPLE"
#           credentialName = "analytics-ss-tls"
#         }
#         hosts = ["analytics-test.complyt.io"]
#       }]
#     }
#   }
# }
# 
# resource "kubernetes_manifest" "istio_virtual_service" {
#   manifest = {
#     apiVersion = "networking.istio.io/v1"
#     kind       = "VirtualService"
#     metadata = {
#       name      = "analytics"
#       namespace = "analytics"
#     }
#     spec = {
#       hosts    = ["analytics-test.complyt.io"]
#       gateways = ["analytics-gateway"]
#       http = [{
#         match = [{
#           uri = {
#             prefix = "/"
#           }
#         }]
#         route = [{
#           destination = {
#             host = "analytics-service"
#             port = {
#               number = 80
#             }
#           }
#         }]
#       }]
#     }
#   }
# }
# 
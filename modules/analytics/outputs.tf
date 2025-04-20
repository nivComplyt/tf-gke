output "service_name" {
  value = kubernetes_service.app.metadata[0].name
}

output "deployment_name" {
  value = kubernetes_deployment.app.metadata[0].name
}

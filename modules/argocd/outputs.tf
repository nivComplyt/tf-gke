output "argocd_namespace" {
  value = kubernetes_namespace.argocd.metadata[0].name
}

output "argocd_server_service" {
  value = helm_release.argocd.name
}

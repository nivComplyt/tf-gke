output "argocd_server_service" {
  value = helm_release.argocd.name
}

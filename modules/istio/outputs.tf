output "istio_namespace" {
  value = "istio"
}

output "istio_ingress_namespace" {
  value = "istio-ingress"
}

# output "injected_namespaces" {
#   value = [for ns in kubernetes_namespace.injected_namespaces : ns.metadata[0].name]
# }
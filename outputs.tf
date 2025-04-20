output "cluster_name" {
  description = "Cluster name"
  value       = module.gke.cluster_name
}

output "node_pool_name" {
  value = module.gke.node_pool_name
}

output "region" {
  description = "GCloud Region"
  value       = var.region
}

output "project_id" {
  description = "GCloud Project ID"
  value       = var.project_id
}

output "cluster_endpoint" {
  description = "GKE Cluster Host/Endpoint"
  value       = module.gke.cluster_endpoint
}
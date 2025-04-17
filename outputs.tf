output "cluster_name" {
  description = "Cluster name"
  value       = google_container_cluster.primary.name
}

output "node_pool_name" {
  value = google_container_node_pool.primary_nodes.name
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
  value       = google_container_cluster.primary.endpoint
}
output "cluster_name" {
  value = google_container_cluster.primary.name
}

output "public_node_pool_name" {
  value = google_container_node_pool.public_pool.name
}

output "private_node_pool_name" {
  value = google_container_node_pool.private_pool.name
}

output "cluster_endpoint" {
  value = google_container_cluster.primary.endpoint
}

output "cluster_ca_certificate" {
  value = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
}

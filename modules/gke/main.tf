resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region

  remove_default_node_pool = true
  initial_node_count       = 3
  deletion_protection      = false

  network    = var.network
  subnetwork = var.subnetwork
}

resource "google_container_node_pool" "primary_nodes" {
  name         = "${var.cluster_name}-nodes"
  location     = var.region
  cluster      = google_container_cluster.primary.name
  node_count   = var.node_count

  node_config {
    machine_type = var.machine_type

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]

    labels = {
      environment = "dev"
    }

    tags = ["gke-node", "${var.project_id}-gke"]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = var.min_node_count
    max_node_count = var.max_node_count
  }
}
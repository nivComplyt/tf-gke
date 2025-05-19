resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  location = var.region
  node_locations = var.node_locations

  remove_default_node_pool = true
  initial_node_count       = 10
  deletion_protection      = false

  network    = var.network
  subnetwork = var.subnetwork

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "public_pool" {
  name       = "${var.cluster_name}-${var.public_pool_name}"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.public_node_count

  node_config {
    machine_type  = var.machine_type
    tags          = ["${var.project_id}-gke", "public-subnet-node"]
    labels = {
      istio = "enabled"
      role  = "public"
      environment = "dev"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
    
    workload_metadata_config {
      mode = "GKE_METADATA"
    }
  }

  autoscaling {
    min_node_count = var.min_public_node_count
    max_node_count = var.max_public_node_count
  }
}

resource "google_container_node_pool" "private_pool" {
  name       = "${var.cluster_name}-${var.private_pool_name}"
  location   = var.region
  cluster    = google_container_cluster.primary.name
  node_count = var.private_node_count

  node_config {
    machine_type  = var.machine_type
    tags          = ["${var.project_id}-gke", "private-subnet-node"]
    labels = {
      role  = "private"
      environment = "dev"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  autoscaling {
    min_node_count = var.min_private_node_count
    max_node_count = var.max_private_node_count
  }
}

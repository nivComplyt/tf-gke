resource "google_compute_network" "vpc" {
  name                    = "${var.project_id}-${var.vpc_name}"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.project_id}-${var.public_subnet_name}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.public_cidr
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "private_subnet" {
  name          = "${var.project_id}-${var.private_subnet_name}"
  region        = var.region
  network       = google_compute_network.vpc.name
  ip_cidr_range = var.private_cidr
  private_ip_google_access = true
}

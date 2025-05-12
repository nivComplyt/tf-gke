terraform {
  backend "gcs" {
    bucket = "complyt_terraform"
    prefix = "dev/gke_internal"
  }
}

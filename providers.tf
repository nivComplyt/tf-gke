terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.30"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.36"
    }

    # helm = {
    #   source = "hashicorp/helm"
    #   version = "2.17.0"
    # }

    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.22"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "4.8.0"
    }
  }
}

data "google_client_config" "default" {}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${module.gke.cluster_endpoint}"
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}

provider "grafana" {
  alias = "monitoring"
  url   = "https://grafana-internal.complyt.io"
  auth  = var.grafana_sa_token
  #insecure_skip_verify = true # Remove once TLS cert is issued 
}

provider "vault" {
  address   = var.vault_address
  token     = var.vault_token
  namespace = "admin"
}

terraform {
  required_providers {
    grafana = {
      source  = "grafana/grafana"
      version = "~> 3.22"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

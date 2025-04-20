resource "kubernetes_deployment" "analytics" {
  metadata {
    name = var.app_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app = var.app_name
        }
      }

      spec {
        container {
          name  = var.app_name
          image = var.image

          port {
            container_port = var.port
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = "${var.app_name}-svc"
  }

  spec {
    selector = {
      app = var.app_name
    }

    port {
      port        = 80
      target_port = var.port
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_namespace" "argocd" {
  metadata {
    name = var.argocd_namespace
  }
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = var.tls_secret_name
    namespace = var.argocd_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = base64encode(var.argocd_tls_crt)
    "tls.key" = base64encode(var.argocd_tls_key)
  }
}

resource "kubernetes_config_map" "cmd_params" {
  metadata {
    name      = "argocd-cmd-params-cm"
    namespace = "argocd"
  }

  data = {
    "server.insecure" = "true"
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd-gateway"
      namespace = var.argocd_namespace
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [{
        port = {
          number   = 443
          name     = "https"
          protocol = "HTTPS"
        }
        tls = {
          mode           = "SIMPLE"
          credentialName = var.tls_secret_name
        }
        hosts = [var.argocd_domain]
      }]
    }
  }
}

resource "kubernetes_manifest" "virtualservice" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "VirtualService"
    metadata = {
      name      = "argocd"
      namespace = var.argocd_namespace
    }
    spec = {
      hosts    = [var.argocd_domain]
      gateways = ["argocd-gateway"]
      http = [{
        match = [{
          uri = {
            prefix = "/"
          }
        }]
        route = [{
          destination = {
            host = "argocd-server"
            port = {
              number = 80
            }
          }
        }]
      }]
    }
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.argocd_version
  namespace  = kubernetes_namespace.argocd.metadata[0].name
  create_namespace = false

  values = [
    yamlencode({
      server = {
        service = {
          type = "LoadBalancer"
        },
        extraArgs = ["--insecure"]
      }
    })
  ]
}

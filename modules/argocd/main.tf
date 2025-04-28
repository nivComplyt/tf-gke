resource "kubernetes_secret" "tls" {
  metadata {
    name      = var.tls_secret_name
    namespace = var.argocd_namespace
  }

  type = "kubernetes.io/tls"

  data = {
    "tls.crt" = var.argocd_tls_crt
    "tls.key" = var.argocd_tls_key
  }
}

resource "kubernetes_manifest" "gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1"
    kind       = "Gateway"
    metadata = {
      name      = "argocd-gateway"
      namespace = "argocd"
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
      namespace = "argocd"
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
            host = "argocd-server.argocd.svc.cluster.local"
            port = {
              number = 80
            }
          }
        }]
      }]
    }
  }
}

resource "kubernetes_secret" "argocd_github_app" {
  metadata {
    name      = "argocd-repo-github-app"
    namespace = var.argocd_namespace
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    type            = "git"
    url             = "https://github.com/Complyt/argocd"
    project         = "default"
    githubAppID     = var.github_app_id
    githubAppInstallationID = var.github_app_installation_id
    githubAppPrivateKey     = file("${path.root}/secrets/github-app.pem")
  }

  type = "Opaque"
}

resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = var.argocd_version
  namespace  = var.argocd_namespace
  create_namespace = true

  values = [
    yamlencode({
      crds = {
        install = true
      }

      configs = {
        repositories = {}
      }

      global = {
        tolerations = [
          {
            key      = "kubernetes.io/arch"
            operator = "Equal"
            value    = "arm64"
            effect   = "NoSchedule"
          }
        ]
      },

      server = {
        service = {
          type = "ClusterIP"
        },
        extraArgs = ["--insecure"],   # TODO: Remove once we have a real cert
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "role"
                      operator = "In"
                      values   = ["private"]
                    }
                  ]
                }
              ]
            }
          }
        }
      },

      repoServer = {
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "role"
                      operator = "In"
                      values   = ["private"]
                    }
                  ]
                }
              ]
            }
          }
        }
      },

      controller = {
        affinity = {
          nodeAffinity = {
            requiredDuringSchedulingIgnoredDuringExecution = {
              nodeSelectorTerms = [
                {
                  matchExpressions = [
                    {
                      key      = "role"
                      operator = "In"
                      values   = ["private"]
                    }
                  ]
                }
              ]
            }
          }
        }
      },

      redisSecretInit = {
        podAnnotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
    })
  ]

  depends_on = [kubernetes_secret.argocd_github_app]
}

resource "kubernetes_manifest" "app_of_apps" {
  manifest = yamldecode(file("${path.module}/app-of-apps.yaml"))
  depends_on = [helm_release.argocd]
}

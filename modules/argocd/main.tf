locals {
  private_node_affinity = {
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
          credentialName = var.wildcard_tls_secret
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
        cm = {
          configManagementPlugins = <<-EOT
            - name: avp
              init:
                command: ["sh", "-c", "argocd-vault-plugin generate ./"]
              generate:
                command: ["sh", "-c", "argocd-vault-plugin generate ./"]
          EOT
        }
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
        #extraArgs = ["--insecure"],   # TODO: Remove once we have a real cert
        affinity = local.private_node_affinity
      },

      repoServer = {
        affinity = local.private_node_affinity
        volumes = [
          {
            name = "custom-tools"
            emptyDir = {}
          }
        ]
        volumeMounts = [
          {
            mountPath = "/usr/local/bin/argocd-vault-plugin"
            name      = "custom-tools"
            subPath   = "argocd-vault-plugin"
          }
        ]
        initContainers = [
          {
            name  = "install-argocd-vault-plugin"
            image = "alpine:latest"
            command = [ "sh", "-c" ]
            args = [
              <<-EOT
                apk add --no-cache curl && \
                curl -L -o /custom-tools/argocd-vault-plugin https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v${var.avp_version}/argocd-vault-plugin_${var.avp_version}_linux_amd64 && \
                chmod +x /custom-tools/argocd-vault-plugin
              EOT
            ]
            volumeMounts = [
              {
                mountPath = "/custom-tools"
                name      = "custom-tools"
              }
            ]
          }
        ]
        env = [
          {
            name  = "AVP_TYPE"
            value = "vault"
          },
          {
            name  = "AVP_AUTH_TYPE"
            value = "kubernetes"
          },
          {
            name  = "AVP_VAULT_ADDR"
            value = var.vault_address
          },
          {
            name  = "AVP_K8S_ROLE"
            value = "argocd"
          },
          {
            name  = "AVP_K8S_TOKEN_PATH"
            value = "/var/run/secrets/kubernetes.io/serviceaccount/token"
          }
        ]
      },

      controller = {
        affinity = local.private_node_affinity
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

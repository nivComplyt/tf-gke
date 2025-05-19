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

resource "kubernetes_config_map" "argocd_cmp_avp" {
  metadata {
    name      = "argocd-cmp-avp"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/compare-options"          = "IgnoreExtraneous"
      "argocd.argoproj.io/config-management-plugin" = "avp"
    }
  }
  data = {
    "plugin.yaml" = <<-YAML
      apiVersion: argoproj.io/v1alpha1
      kind: ConfigManagementPlugin
      metadata:
        name: avp
      spec:
        init:
          command: [/home/argocd/cmp-server/plugins/avp/argocd-vault-plugin]
          args: ["generate", "."]
        generate:
          command: [/home/argocd/cmp-server/plugins/avp/argocd-vault-plugin]
          args: ["generate", "."]
        discover:
          fileName: Chart.yaml
    YAML
  }
}

resource "helm_release" "argocd" {
  name             = "argocd"
  chart            = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  version          = var.argocd_version
  namespace        = var.argocd_namespace
  create_namespace = true

  values = [
    yamlencode({
      crds = { install = true }

      global = {
        tolerations = var.arm64_tolerations
      }

      server = {
        service = { type = "ClusterIP" }
        extraArgs = ["--insecure"]
        ingress = { enabled = false }
        config = { url = "https://${var.argocd_domain}" }
      }

      repoServer = {
        affinity = local.private_node_affinity

        volumes = [
          {
            name = "custom-tools"
            emptyDir = {}
          },
          {
            name = "cmp-plugin-config"
            configMap = {
              name = "argocd-cmp-avp"
            }
          },
          {
            name = "cmp-config-dir"
            emptyDir = {}
          }
        ]

        initContainers = [
          {
            name    = "download-avp"
            image   = "alpine:3.12"
            command = ["/bin/sh", "-c"]
            args    = [
              <<-EOT
                apk add --no-cache curl && \
                mkdir -p /custom-tools/avp && \
                curl -L -o /custom-tools/avp/argocd-vault-plugin https://github.com/argoproj-labs/argocd-vault-plugin/releases/download/v${var.avp_version}/argocd-vault-plugin_${var.avp_version}_linux_arm64 && \
                chmod +x /custom-tools/avp/argocd-vault-plugin && \
                mkdir -p /home/argocd/cmp-server/config
              EOT
            ]
            volumeMounts = [
              {
                name      = "custom-tools"
                mountPath = "/custom-tools"
              },
              {
                name      = "cmp-config-dir"
                mountPath = "/home/argocd/cmp-server/config"
              }
            ]
          }
        ]

        extraVolumeMounts = [
          {
            name      = "custom-tools"
            mountPath = "/home/argocd/cmp-server/plugins/avp"
            subPath   = "avp"
          },
          {
            name      = "cmp-config-dir"
            mountPath = "/home/argocd/cmp-server/config"
          },
          {
            name      = "cmp-plugin-config"
            mountPath = "/home/argocd/cmp-server/config"
          }
        ]

        env = [
          { name = "AVP_TYPE", value = "vault" },
          { name = "AVP_AUTH_TYPE", value = "kubernetes" },
          { name = "AVP_VAULT_ADDR", value = var.vault_address },
          { name = "AVP_K8S_ROLE", value = "argocd" },
          { name = "AVP_K8S_TOKEN_PATH", value = "/var/run/secrets/kubernetes.io/serviceaccount/token" }
        ]
      }

      controller = {
        affinity = local.private_node_affinity
      }

      redisSecretInit = {
        podAnnotations = {
          "sidecar.istio.io/inject" = "false"
        }
      }
    })
  ]

  depends_on = [kubernetes_secret.argocd_github_app]
}

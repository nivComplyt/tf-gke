resource "kubernetes_namespace" "istio_ingress" {
  metadata {
    name = "istio-ingress"
  }
}

resource "helm_release" "istio_base" {
  name       = "istio-base"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "base"
  version    = var.istio_version
  namespace  = "istio-system"
  create_namespace = true
}

resource "helm_release" "istiod" {
  name       = "istiod"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "istiod"
  version    = var.istio_version
  namespace  = "istio-system"
  timeout    = 360

  values = [
    yamlencode({
      tolerations = [
        {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      ]
    })
  ]

  depends_on = [helm_release.istio_base]
}

resource "helm_release" "istio_ingress" {
  name       = "istio-ingressgateway"
  repository = "https://istio-release.storage.googleapis.com/charts"
  chart      = "gateway"
  version    = var.istio_version
  namespace  = "istio-ingress"
  create_namespace = true
  depends_on = [helm_release.istiod]

  values = [
    yamlencode({
      service = {
        type = "LoadBalancer"
        # loadBalancerIP = null   # For VPN
        # annotations = {
        #   "cloud.google.com/load-balancer-type" = "Internal"
        # }
        ports = [
          {
            name       = "http"
            port       = 80
            targetPort = 8080
            protocol    = "TCP"
          },
          {
            name       = "https"
            port       = 443
            targetPort = 8443
            protocol    = "TCP"
          }
        ]
      }

      ingressPorts = [
        {
          name          = "http"
          port          = 8080
          targetPort    = 8080
        },
        {
          name          = "https"
          port          = 8443
          targetPort    = 8443
        }
      ]

      deployment = {
        containerPorts = [
          {
            containerPort = 8080
            protocol      = "TCP"
            name          = "http2"
          },
          {
            containerPort = 8443
            protocol      = "TCP"
            name          = "https"
          }
        ]
      }

      affinity = {
        nodeAffinity = {
          requiredDuringSchedulingIgnoredDuringExecution = {
            nodeSelectorTerms = [
              {
                matchExpressions = [
                  {
                    key      = "role"
                    operator = "In"
                    values   = ["public"]
                  }
                ]
              }
            ]
          }
        }
      }

      tolerations = [
        {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = "arm64"
          effect   = "NoSchedule"
        }
      ]

      labels = {
        istio = "ingressgateway"
      }
    })
  ]
}

resource "kubernetes_manifest" "inject_labels" {
  for_each = toset(var.inject_namespaces)

  manifest = {
    apiVersion = "v1"
    kind       = "Namespace"
    metadata = {
      name   = each.value
      labels = {
        "istio-injection" = "enabled"
      }
    }
  }
}

resource "kubernetes_secret" "tls" {
  metadata {
    name      = var.tls_secret_name
    namespace = "istio-ingress"
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = var.argocd_tls_crt
    "tls.key" = var.argocd_tls_key
  }
  depends_on = [kubernetes_namespace.istio_ingress]
}
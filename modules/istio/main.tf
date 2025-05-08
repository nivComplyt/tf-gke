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

  values = [
    yamlencode({
      global = {
        proxy = {
          accessLogEncoding = "JSON"
          accessLogFormat   = "{\"start_time\":\"%START_TIME%\",\"method\":\"%REQ(:METHOD)%\",\"path\":\"%REQ(X-ENVOY-ORIGINAL-PATH?:PATH)%\",\"protocol\":\"%PROTOCOL%\",\"response_code\":\"%RESPONSE_CODE%\",\"response_flags\":\"%RESPONSE_FLAGS%\",\"bytes_received\":\"%BYTES_RECEIVED%\",\"bytes_sent\":\"%BYTES_SENT%\",\"duration\":\"%DURATION%\",\"user_agent\":\"%REQ(USER-AGENT)%\",\"upstream_host\":\"%UPSTREAM_HOST%\"}"
        }
      }
    })
  ]
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
        externalTrafficPolicy = "Local"
        ports = [
          {
            name       = "http2"
            port       = 80
            targetPort = 80
            protocol    = "TCP"
          },
          {
            name       = "https"
            port       = 443
            targetPort = 443
            protocol    = "TCP"
          }
        ]
      }

      meshConfig = {
        defaultConfig = {
          proxyMetadata = {
            ISTIO_META_DNS_CAPTURE       = "true"
            ISTIO_META_DNS_AUTO_ALLOCATE = "true"
          }
        }
      }

      podAnnotations = {
        "proxy.istio.io/config" = jsonencode({
          proxyMetadata = {
            ISTIO_META_DNS_CAPTURE       = "true"
            ISTIO_META_DNS_AUTO_ALLOCATE = "true"
          }
        })
      }

      deployment = {
        containerPorts = [
          {
            containerPort = 80
            protocol      = "TCP"
            name          = "http2"
          },
          {
            containerPort = 443
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

resource "kubernetes_manifest" "global_gateway" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Gateway"
    metadata = {
      name      = "complyt-cloud-gateway"
      namespace = "istio-ingress"
    }
    spec = {
      selector = {
        istio = "ingressgateway"
      }
      servers = [
        {
          port = {
            number   = 443
            name     = "https"
            protocol = "HTTPS"
          }
          tls = {
            mode           = "SIMPLE"
            credentialName = var.wildcard_tls_secret
          }
          hosts = [
            "*.complyt.cloud"
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "sidecar_egress_all" {
  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "Sidecar"
    metadata = {
      name      = "egress-all"
      namespace = "istio-ingress"
    }
    spec = {
      egress = [
        {
          hosts = ["*/*"]
        }
      ]
    }
  }
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

resource "kubernetes_secret" "wildcard_tls" {
  metadata {
    name      = var.wildcard_tls_secret
    namespace = "istio-ingress"
  }
  type = "kubernetes.io/tls"
  data = {
    "tls.crt" = var.wildcard_tls_crt
    "tls.key" = var.wildcard_tls_key
  }
  depends_on = [kubernetes_namespace.istio_ingress]
}

resource "kubernetes_manifest" "virtualservice_app" {
  for_each = var.apps

  manifest = {
    apiVersion = "networking.istio.io/v1beta1"
    kind       = "VirtualService"
    metadata = {
      name      = each.key
      namespace = each.value.namespace
    }
    spec = {
      hosts    = ["${each.key}.complyt.cloud"]
      gateways = ["istio-ingress/complyt-cloud-gateway"]
      http = [
        {
          match = [
            {
              uri = {
                prefix = "/"
              }
            }
          ]
          route = [
            {
              destination = {
                host = "${each.value.service_name}.${each.value.namespace}.svc.cluster.local"
                port = {
                  number = each.value.service_port
                }
              }
            }
          ]
        }
      ]
    }
  }
}

resource "kubernetes_manifest" "authorization_policy_nordlayer" {
  manifest = {
    apiVersion = "security.istio.io/v1beta1"
    kind       = "AuthorizationPolicy"
    metadata = {
      name      = "allow-only-nordlayer"
      namespace = "istio-ingress"
    }
    spec = {
      selector = {
        matchLabels = {
          istio = "ingressgateway"
          app = "istio-ingressgateway"
        }
      }
      action = "ALLOW"
      rules = [
        {
          from = [
            {
              source = {
                ipBlocks = var.vpn_ip_block
              }
            }
          ]
        }
      ]
    }
  }
}

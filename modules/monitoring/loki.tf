resource "helm_release" "loki_stack" {
  name       = "loki-stack"
  namespace  = "monitoring"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "loki-stack"
  version    = "2.10.2"

  set {
    name  = "loki.enabled"
    value = "true"
  }

  set {
    name  = "promtail.enabled"
    value = "true"
  }

  set {
    name  = "promtail.lokiServiceName"
    value = "loki-stack"
  }

  set {
    name  = "promtail.config.scrape_configs[0].job_name"
    value = "kubernetes-pods"
  }

  set {
    name  = "promtail.config.scrape_configs[0].kubernetes_sd_configs[0].role"
    value = "pod"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].source_labels[0]"
    value = "__meta_kubernetes_pod_container_name"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].regex"
    value = "istio-proxy"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[0].action"
    value = "drop"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[1].source_labels[0]"
    value = "__meta_kubernetes_namespace"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[1].target_label"
    value = "namespace"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[2].source_labels[0]"
    value = "__meta_kubernetes_pod_name"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[2].target_label"
    value = "pod"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[3].source_labels[0]"
    value = "__meta_kubernetes_pod_container_name"
  }

  set {
    name  = "promtail.config.scrape_configs[0].relabel_configs[3].target_label"
    value = "container"
  }

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "grafana.sidecar.datasources.enabled"
    value = "false"
  }

  set {
    name  = "loki.tolerations[0].key"
    value = "kubernetes.io/arch"
  }
  set {
    name  = "loki.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "loki.tolerations[0].value"
    value = "arm64"
  }
  set {
    name  = "loki.tolerations[0].effect"
    value = "NoSchedule"
  }

  set {
    name  = "promtail.tolerations[0].key"
    value = "kubernetes.io/arch"
  }
  set {
    name  = "promtail.tolerations[0].operator"
    value = "Equal"
  }
  set {
    name  = "promtail.tolerations[0].value"
    value = "arm64"
  }
  set {
    name  = "promtail.tolerations[0].effect"
    value = "NoSchedule"
  }
}

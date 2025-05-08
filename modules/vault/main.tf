resource "kubernetes_service_account" "token_reviewer" {
  metadata {
    name      = "vault-token-reviewer"
    namespace = "kube-system"
  }
  automount_service_account_token = true
}

resource "kubernetes_cluster_role_binding" "vault-token-reviewer" {
  metadata {
    name = "vault-token-reviewer-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = "system:auth-delegator"
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.token_reviewer.metadata[0].name
    namespace = kubernetes_service_account.token_reviewer.metadata[0].namespace
  }
}

resource "kubernetes_secret" "token_reviewer_secret" {
  metadata {
    name      = "vault-token-reviewer-token"
    namespace = kubernetes_service_account.token_reviewer.metadata[0].namespace
    annotations = {
      "kubernetes.io/service-account.name" = kubernetes_service_account.token_reviewer.metadata[0].name
    }
  }
  type = "kubernetes.io/service-account-token"
}

data "kubernetes_secret" "token_reviewer_token" {
  metadata {
    name      = kubernetes_secret.token_reviewer_secret.metadata[0].name
    namespace = kubernetes_secret.token_reviewer_secret.metadata[0].namespace
  }
}

resource "vault_kubernetes_auth_backend_config" "vault_k8s_auth_config" {
  backend            = "gke-internal"
  kubernetes_host    = var.kubernetes_host
  kubernetes_ca_cert = var.kubernetes_ca_cert
  token_reviewer_jwt = data.kubernetes_secret.token_reviewer_token.data.token
}

resource "vault_policy" "app_policies" {
  for_each = var.apps
  name     = "argocd-${each.key}"
  policy = <<EOT
path "secret/data/gke-internal/${each.key}/*" {
  capabilities = ["read"]
}
EOT
}

resource "vault_kubernetes_auth_backend_role" "app_roles" {
  for_each = var.apps
  backend                          = "gke-internal"
  role_name                        = "argocd-${each.key}"
  bound_service_account_names      = ["argocd-repo-server"]
  bound_service_account_namespaces = ["argocd"]
  token_policies = [vault_policy.app_policies[each.key].name]
  token_ttl      = 3600
}
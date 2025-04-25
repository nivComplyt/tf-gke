module "network" {
  source              = "./modules/network"
  project_id          = var.project_id
  region              = var.region
  vpc_name            = var.vpc_name
  private_subnet_name = var.private_subnet_name
  public_subnet_name  = var.public_subnet_name
  public_cidr         = var.public_cidr
  private_cidr        = var.private_cidr
}

module "gke" {
  source                 = "./modules/gke"
  project_id             = var.project_id
  region                 = var.region
  cluster_name           = var.cluster_name
  public_pool_name       = var.public_pool_name
  private_pool_name      = var.private_pool_name
  public_node_count      = var.public_node_count
  private_node_count     = var.private_node_count
  machine_type           = var.machine_type
  node_locations         = var.node_locations
  min_public_node_count  = var.min_public_node_count
  max_public_node_count  = var.max_public_node_count
  min_private_node_count = var.min_private_node_count
  max_private_node_count = var.max_private_node_count
  network                = module.network.network_id
  subnetwork             = module.network.subnet_id
}

module "istio" {
  source            = "./modules/istio"
  istio_version     = var.istio_version
  inject_namespaces = var.inject_namespaces
  argocd_tls_crt    = var.argocd_tls_crt
  argocd_tls_key    = var.argocd_tls_key
  tls_secret_name   = "argocd-tls"

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.gke]
}

module "argocd" {
  source                     = "./modules/argocd"
  argocd_namespace           = var.argocd_namespace
  argocd_version             = var.argocd_version
  argocd_tls_crt             = var.argocd_tls_crt
  argocd_tls_key             = var.argocd_tls_key
  tls_secret_name            = "argocd-tls"
  argocd_domain              = var.argocd_domain
  #github_app_pem             = var.github_app_pem
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.istio]
}

# module "lgtm_stack" {
#   source = "./modules/lgtm"
# 
#   loki_namespace    = "monitoring"
#   grafana_namespace = "monitoring"
#   tempo_namespace   = "monitoring"
#   mimir_namespace   = "monitoring"
# 
#   providers = {
#     helm       = helm
#     kubernetes = kubernetes
#   }
# }

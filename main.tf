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
  source              = "./modules/istio"
  istio_version       = var.istio_version
  inject_namespaces   = var.inject_namespaces
  wildcard_tls_secret = var.wildcard_tls_secret
  wildcard_tls_crt    = var.wildcard_tls_crt
  wildcard_tls_key    = var.wildcard_tls_key
  apps                = var.apps
  vpn_ip_block        = var.vpn_ip_block

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
  argocd_domain              = var.argocd_domain
  wildcard_tls_secret        = var.wildcard_tls_secret
  wildcard_tls_crt           = var.wildcard_tls_crt
  wildcard_tls_key           = var.wildcard_tls_key
  github_app_id              = var.github_app_id
  github_app_installation_id = var.github_app_installation_id

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }

  depends_on = [module.istio]
}

module "monitoring" {
  source = "./modules/monitoring"

  loki_version    = var.loki_version
  grafana_version = var.grafana_version
  #tempo_version   = var.tempo_version
  #mimir_version   = var.mimir_version
  grafana_admin_password = var.grafana_admin_password
  wildcard_tls_secret    = var.wildcard_tls_secret
  vpn_ip_block           = var.vpn_ip_block

  providers = {
    helm       = helm
    kubernetes = kubernetes
  }
}

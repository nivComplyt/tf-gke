module "network" {
  source     = "./modules/network"
  project_id = var.project_id
  region     = var.region
  vpc_cidr   = var.vpc_cidr
}

module "gke" {
  source         = "./modules/gke"
  project_id     = var.project_id
  region         = var.region
  cluster_name   = var.cluster_name
  node_count     = var.node_count
  machine_type   = var.machine_type
  min_node_count = var.min_node_count
  max_node_count = var.max_node_count
  network        = module.network.network_id
  subnetwork     = module.network.subnet_id
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
  source           = "./modules/argocd"
  argocd_namespace = var.argocd_namespace
  argocd_version   = var.argocd_version
  argocd_tls_crt   = var.argocd_tls_crt
  argocd_tls_key   = var.argocd_tls_key
  tls_secret_name  = "argocd-tls"
  argocd_domain    = var.argocd_domain

  providers = {
    helm       = helm
    kubernetes = kubernetes
    #kubectl    = kubectl
  }

  depends_on = [module.istio]
}

# module "analytics" {
#   source          = "./modules/analytics"
#   app_name        = var.app_name
#   image           = var.image
#   replicas        = var.replicas
#   port            = var.port
#   docker_username = var.docker_username
#   docker_password = var.docker_password
#   tls_cert        = var.tls_cert
#   tls_key         = var.tls_key
#   providers = {
#     kubernetes = kubernetes
#   }
# }


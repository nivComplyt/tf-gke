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

# module "analytics" {
#   source      = "./modules/analytics"
#   app_name    = "analytics"
#   image       = "complyt/analytics:latest"
#   port        = 8080
# }
# 
# module "app2" {
#   source      = "./modules/autofiling"
#   app_name    = "autofiling"
#   image       = "complyt/autofiling-nc:latest"
#   port        = 80
# }

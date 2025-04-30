############################## Project ##############################
variable "project_id" {
  description = "The project ID to host the cluster in"
  type        = string
  default     = "complyt-dev"
}

variable "region" {
  description = "The region to host the cluster in"
  type        = string
  default     = "us-central1"
}

############################## Network ##############################
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default     = "internal-vpc"
}

variable "private_subnet_name" {
  description = "The name of the private subnet"
  type        = string
  default     = "internal-private-subnet"
}

variable "public_subnet_name" {
  description = "The name of the public subnet"
  type        = string
  default     = "internal-public-subnet"
}

variable "public_cidr" {
  default = "10.10.1.0/24"
}

variable "private_cidr" {
  default = "10.10.2.0/24"
}

############################## GKE ##############################
variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "dev-cluster"
}

variable "public_pool_name" {
  description = "The name for the GKE public nodes pool"
  type        = string
  default     = "public-pool"
}

variable "private_pool_name" {
  description = "The name for the GKE private nodes pool"
  type        = string
  default     = "private-pool"
}

variable "env_name" {
  description = "The environment for the GKE cluster"
  type        = string
  default     = "prod"
}

variable "machine_type" {
  description = "Type of machine to use for nodes"
  type        = string
  default     = "t2a-standard-8"
}

variable "node_locations" {
  description = "Location of machines to use for nodes"
  type        = list(string)
  default     = ["us-central1-a", "us-central1-b", "us-central1-f"]
}

variable "public_node_count" {
  description = "Initial number of public subnet nodes"
  type        = number
  default     = 1
}

variable "min_public_node_count" {
  description = "Minimum number of public nodes for autoscaling"
  type        = number
  default     = 1
}

variable "max_public_node_count" {
  description = "Maximum number of public nodes for autoscaling"
  type        = number
  default     = 2
}

variable "private_node_count" {
  description = "Initial number of private subnet nodes"
  type        = number
  default     = 8
}

variable "min_private_node_count" {
  description = "Minimum number of private nodes for autoscaling"
  type        = number
  default     = 4
}

variable "max_private_node_count" {
  description = "Maximum number of priavte nodes for autoscaling"
  type        = number
  default     = 12
}

############################## Istio ##############################
variable "istio_version" {
  description = "Istio chart version to install"
  type        = string
  default     = "1.25.2"
}

variable "inject_namespaces" {
  description = "List of namespaces to label for automatic Istio sidecar injection"
  type        = list(string)
  default     = ["argocd"]
}

variable "wildcard_tls_secret" {
  description = "Name of TLS secret to create and reference in Gateway"
  type        = string
  default     = "wildcard-tls"
}

variable "wildcard_tls_crt" {
  description = "Path to Base64-encoded TLS certificate"
  type        = string
  sensitive   = true
  default     = "./secrets/wildcard.crt"
}

variable "wildcard_tls_key" {
  description = "Path to Base64-encoded TLS private key"
  type        = string
  sensitive   = true
  default     = "./secrets/wildcard.key"
}

variable "apps" {
  type = map(object({
    namespace    = string
    service_port = number
    service_name = string
  }))
  default = {
    analytics = {
      namespace    = "analytics"
      service_port = 80
      service_name = "analytics-service"
    }
    internal = {
      namespace    = "internal"
      service_port = 3000
      service_name = "internal-internal"
    }
    assessment = {
      namespace    = "assessment"
      service_port = 80
      service_name = "analytics-assessment-service"
    }
    autofiling = {
      namespace    = "autofiling"
      service_port = 80
      service_name = "frontend"
    }
  }
}

variable "vpn_ip_block" {
  description = "List of Allowed VPN static IP address for Istio Ingress Gateway access"
  type        = list(string)
  default     = ["205.234.190.10/32"]
}

############################## ArgoCD ##############################
variable "argocd_namespace" {
  description = "Namespace to install Argo CD in"
  type        = string
  default     = "argocd"
}

variable "argocd_version" {
  description = "Helm chart version for Argo CD"
  type        = string
  default     = "7.8.27" # This maps to Argo CD v2.14.x
}

variable "argocd_domain" {
  description = "Public domain for Argo CD UI"
  type        = string
  default     = "argocd.complyt.cloud"
}

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

############################## LGTM Stack ##############################
variable "loki_version" {
  description = "Version for Loki"
  type        = string
  default     = "6.20.0"
}

variable "grafana_version" {
  description = "Version for Grafana"
  type        = string
  default     = "8.13.1"
}

variable "tempo_version" {
  description = "Version for Tempo"
  type        = string
  default     = "1.21.0"
}

variable "mimir_version" {
  description = "Version for Mimir"
  type        = string
  default     = "5.7.0"
}

variable "grafana_admin_password" {
  description = "Init password for Grafana UI"
  type        = string
  default     = "admin"
}
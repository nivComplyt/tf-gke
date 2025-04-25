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
  default     = "demo-cluster"
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
  default     = "t2a-standard-4"
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

variable "private_node_count" {
  description = "Initial number of private subnet nodes"
  type        = number
  default     = 10
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

variable "min_private_node_count" {
  description = "Minimum number of private nodes for autoscaling"
  type        = number
  default     = 5
}

variable "max_private_node_count" {
  description = "Maximum number of priavte nodes for autoscaling"
  type        = number
  default     = 15
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

variable "argocd_tls_crt" {
  description = "Base64-encoded TLS certificate"
  type        = string
  sensitive   = true
  default     = "./secrets/argocd.crt"
}

variable "argocd_tls_key" {
  description = "Base64-encoded TLS private key"
  type        = string
  sensitive   = true
  default     = "./secrets/argocd.key"
}

variable "tls_secret_name" {
  description = "Name of TLS secret to create and reference in Gateway"
  type        = string
  default     = "argocd-tls"
}

variable "argocd_domain" {
  description = "Public domain for Argo CD UI"
  type        = string
  default     = "argocd.complyt.cloud"
}

# variable "github_app_pem" {
#   description = "Path for GitHub App private key"
#   type        = string
#   sensitive   = true
#   default     = "./secrets/github-app.pem"
# }

variable "github_app_id" {
  description = "GitHub App ID"
  type        = string
}

variable "github_app_installation_id" {
  description = "GitHub App Installation ID"
  type        = string
}

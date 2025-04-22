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
variable "vpc_cidr" {
  description = "CIDR block for custom VPC subnet"
  type        = string
  default     = "10.10.0.0/16"
}

############################## GKE ##############################
variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "demo-cluster"
}

variable "env_name" {
  description = "The environment for the GKE cluster"
  type        = string
  default     = "prod"
}

variable "machine_type" {
  description = "Type of machine to use for nodes"
  type        = string
  default     = "e2-medium"
}

variable "node_count" {
  description = "Initial number of nodes"
  type        = number
  default     = 1
}

variable "min_node_count" {
  description = "Minimum number of nodes for autoscaling"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 5
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
}

variable "argocd_tls_key" {
  description = "Base64-encoded TLS private key"
  type        = string
  sensitive   = true
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

############################## Docker Cradentials ##############################
variable "docker_username" {
  description = "Docker Hub username"
  type        = string
  sensitive   = true
}

variable "docker_password" {
  description = "Docker Hub password"
  type        = string
  sensitive   = true
}

# ############################## Analytics App ##############################
# variable "app_name" {
#   description = "Name of the app"
#   type        = string
#   default     = "analytics"
# }
# 
# variable "image" {
#   description = "Container image for analytics app deployment"
#   type        = string
#   default     = "complyt/analytics:latest"
# }
# 
# variable "replicas" {
#   description = "Container replicas for deployment"
#   type        = string
#   default     = 2
# }
# 
# variable "port" {
#   description = "Container port exposed"
#   type        = number
#   default     = 3000
# }
# 
# variable "tls_cert" {
#   description = "Base64-encoded TLS certificate"
#   type        = string
#   sensitive   = true
# }
# 
# variable "tls_key" {
#   description = "Base64-encoded TLS private key"
#   type        = string
#   sensitive   = true
# }
# 
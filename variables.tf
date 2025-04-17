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

variable "cluster_name" {
  description = "The name for the GKE cluster"
  type        = string
  default     = "test-cluster"
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
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes for autoscaling"
  type        = number
  default     = 3
}

variable "vpc_cidr" {
  description = "CIDR block for custom VPC subnet"
  type        = string
  default     = "10.10.0.0/16"
}
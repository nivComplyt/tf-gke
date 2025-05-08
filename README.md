# Terraform Infrastructure Configuration

This document lists all available configuration variables for setting up the infrastructure modules.

## Project Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| project_id | The project ID to host the cluster in | "complyt-dev" |
| region | The region to host the cluster in | "us-central1" |

---

## Network Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| vpc_name | The name of the VPC | "internal-vpc" |
| private_subnet_name | The name of the private subnet | "internal-private-subnet" |
| public_subnet_name | The name of the public subnet | "internal-public-subnet" |
| public_cidr | (No description provided) | "10.10.1.0/24" |
| private_cidr | (No description provided) | "10.10.2.0/24" |

---

## GKE Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| cluster_name | The name for the GKE cluster | "dev-cluster" |
| public_pool_name | The name for the GKE public nodes pool | "public-pool" |
| private_pool_name | The name for the GKE private nodes pool | "private-pool" |
| env_name | The environment for the GKE cluster | "prod" |
| machine_type | Type of machine to use for nodes | "t2a-standard-8" |
| node_locations | Location of machines to use for nodes | ["us-central1-a", "us-central1-b", "us-central1-f"] |
| public_node_count | Initial number of public subnet nodes | 1 |
| min_public_node_count | Minimum number of public nodes for autoscaling | 1 |
| max_public_node_count | Maximum number of public nodes for autoscaling | 2 |
| private_node_count | Initial number of private subnet nodes | 8 |
| min_private_node_count | Minimum number of private nodes for autoscaling | 4 |
| max_private_node_count | Maximum number of priavte nodes for autoscaling | 12 |
| arm64_tolerations | Toleration for ARM64 nodes | [ |

---

## Applications Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| apps | (No description provided) | { |

---

## Istio Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| istio_version | Istio chart version to install | "1.25.2" |
| inject_namespaces | List of namespaces to label for automatic Istio sidecar injection | ["argocd"] |
| wildcard_tls_secret | Name of TLS secret to create and reference in Gateway | "wildcard-tls" |
| wildcard_tls_crt | Path to Base64-encoded TLS certificate | "./secrets/wildcard-tls.crt" |
| wildcard_tls_key | Path to Base64-encoded TLS private key | "./secrets/wildcard-tls.key" |
| vpn_ip_block | List of Allowed VPN static IP address for Istio Ingress Gateway access | ["205.234.190.10/32"] |

---

## ArgoCD Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| argocd_namespace | Namespace to install Argo CD in | "argocd" |
| argocd_version | Helm chart version for Argo CD | "7.8.27" # This maps to Argo CD v2.14.x |
| argocd_domain | Public domain for Argo CD UI | "argocd.complyt.cloud" |
| github_app_id | GitHub App ID | (No default) |
| github_app_installation_id | GitHub App Installation ID | (No default) |
| avp_version | Version of argocd-vault-plugin to install | "1.18.1" |

---

## Monitoring - LGTM Stack Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| loki_version | Version for Loki | "6.20.0" |
| grafana_version | Version for Grafana | "8.13.1" |
| tempo_version | Version for Tempo | "1.21.0" |
| mimir_version | Version for Mimir | "5.7.0" |
| grafana_admin_password | Init password for Grafana UI | "admin" |
| grafana_sa_token | Grafana service account token for provider authentication | (No default) |
| otel_version | Version ofOpenTelemntry | "0.122.5" |
| bucket_name | Name of GCS bucket for Loki data | "loki-data-complyt-dev" |

---

## Hashicorp Vault Module

| Variable Name | Description | Example Value |
| :------------ | :----------- | :------------ |
| vault_address | Vault external address | (No default) |
| vault_token | Vault Token | (No default) |
| github_username | GitHub username for ghcr.io image pulls | (No default) |
| github_pat | GitHub Personal Access Token for ghcr.io | (No default) |
| github_email | GitHub email for ghcr.io image pulls | (No default) |

---


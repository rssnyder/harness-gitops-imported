terraform {
  required_version = ">= 1.6"

  required_providers {
    harness = {
      source  = "harness/harness"
      version = "~> 0.45"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

# credentials come from the environment (HARNESS_ACCOUNT_ID / HARNESS_PLATFORM_API_KEY) - source scripts/load-env.sh first.
provider "harness" {
  endpoint = var.harness_endpoint
}

provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

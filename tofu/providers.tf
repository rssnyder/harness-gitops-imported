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

# credentials are read from the environment: HARNESS_ACCOUNT_ID and
# HARNESS_PLATFORM_API_KEY (note: correct spelling - the repo's .env has a
# typo, "HARNESS_PLAFORM_API_KEY". source ../scripts/load-env.sh instead of
# ../.env directly to get the corrected export). leaving this block empty
# lets the provider fall back to its built-in env var defaults.
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

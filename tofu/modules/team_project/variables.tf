terraform {
  required_providers {
    harness = {
      source = "harness/harness"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}

variable "org_id" {
  type = string
}

variable "agent_id" {
  description = "Fully qualified (scope-prefixed) identifier of the harness gitops agent, e.g. 'org.gitops.hrns_argocd'."
  type        = string
}

variable "team" {
  description = "Team name. Used verbatim as the project identifier/name, namespace, and argo project name."
  type        = string
}

variable "in_cluster_server" {
  description = "API server URL the agent's own ServiceAccount is authorized against (IN_CLUSTER connection type)."
  type        = string
  default     = "https://kubernetes.default.svc"
}

variable "cluster_name" {
  description = "Name of the shared org-level GitOps cluster entity to reference in this team's AppProject destinations."
  type        = string
}

variable "cluster_identifier" {
  description = "Scope-prefixed identifier of the shared org-level GitOps cluster entity (e.g. 'org.in_cluster')."
  type        = string
}

variable "repo_identifier" {
  description = "Scope-prefixed identifier of the shared org-level GitOps repository entity (e.g. 'org.guestbook')."
  type        = string
}

variable "repo_url" {
  description = "URL of the shared demo repository (must match the harness_platform_gitops_repository.guestbook registration)."
  type        = string
}

variable "agent_namespace" {
  description = "Namespace the gitops agent is installed in. Argo project metadata must live in this namespace."
  type        = string
}

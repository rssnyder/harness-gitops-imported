variable "harness_endpoint" {
  description = "Harness NextGen API endpoint."
  type        = string
  default     = "https://app.harness.io/gateway"
}

variable "gitops_http_target" {
  description = "Harness GitOps service target the agent reports/polls to."
  type        = string
  default     = "https://app.harness.io/gitops"
}

variable "kubeconfig_path" {
  description = "Path to the kubeconfig for the cluster the argocd agent runs in."
  type        = string
  default     = "../hrns.kubeconfig"
}

variable "org_id" {
  description = "Identifier of the Harness organization created to hold the imported gitops agent and team projects."
  type        = string
  default     = "gitops"
}

variable "org_name" {
  type    = string
  default = "GitOps"
}

variable "agent_namespace" {
  description = "Namespace the existing argocd install (and the harness gitops-agent component) live in."
  type        = string
  default     = "argocd"
}

variable "agent_id" {
  description = "Identifier for the harness gitops agent that wraps the existing argocd install."
  type        = string
  default     = "hrns_argocd"
}

# one namespace + harness project + argo project is created per team,
# isolated from the others: destinations/cluster registration are scoped to
# that team's own namespace only.
variable "teams" {
  description = "Example teams to provision. Each gets its own namespace, Harness project, and Argo CD project scoped to that namespace."
  type        = set(string)
  default     = ["web", "backend", "database"]
}

variable "in_cluster_server" {
  description = "API server URL the agent's own ServiceAccount is authorized against."
  type        = string
  default     = "https://kubernetes.default.svc"
}

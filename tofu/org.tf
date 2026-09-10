# single scope where the existing argocd agent is imported; all team projects live here.
resource "harness_platform_organization" "gitops" {
  identifier  = var.org_id
  name        = var.org_name
  description = "Org-level home for the imported argocd gitops agent and per-team projects"
  tags        = ["source:opentofu"]
}

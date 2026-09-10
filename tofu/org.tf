# the "gitops" org is the single scope where the existing argocd agent is
# imported; every team project below lives inside it so they can all attach
# to the same org-level agent.
resource "harness_platform_organization" "gitops" {
  identifier  = var.org_id
  name        = var.org_name
  description = "Org-level home for the imported argocd gitops agent and per-team projects"
  tags        = ["source:opentofu"]
}

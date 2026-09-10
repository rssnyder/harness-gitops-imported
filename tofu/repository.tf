# the read-only argoproj example-apps repo, used by each team's demo
# guestbook Application (see modules/team_project/demo.tf). Same
# once-per-agent uniqueness constraint applies to repositories as to
# clusters, so this is registered once at org scope and shared, same as
# harness_platform_gitops_cluster.in_cluster.
resource "harness_platform_gitops_repository" "guestbook" {
  org_id     = harness_platform_organization.gitops.id
  agent_id   = local.agent_id_qualified
  identifier = "guestbook"
  upsert     = true

  depends_on = [time_sleep.wait_for_gitops_agent]

  repo {
    repo            = "https://github.com/argoproj/argocd-example-apps.git"
    name            = "guestbook"
    insecure        = true
    connection_type = "HTTPS_ANONYMOUS"
  }
}

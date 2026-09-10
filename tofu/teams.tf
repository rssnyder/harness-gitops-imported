# one module instance per example team - each is fully isolated to its own
# namespace via the module's Argo project (destinations restricted to that
# namespace) mapped 1:1 to the team's Harness project.
module "team" {
  source   = "./modules/team_project"
  for_each = var.teams

  depends_on = [
    harness_platform_gitops_cluster.in_cluster,
    harness_platform_gitops_repository.guestbook,
  ]

  org_id             = harness_platform_organization.gitops.id
  agent_id           = local.agent_id_qualified
  agent_namespace    = var.agent_namespace
  team               = each.key
  in_cluster_server  = var.in_cluster_server
  cluster_name       = harness_platform_gitops_cluster.in_cluster.request[0].cluster[0].name
  cluster_identifier = local.cluster_id_qualified
  repo_identifier    = local.repo_id_qualified
  repo_url           = harness_platform_gitops_repository.guestbook.repo[0].repo
}

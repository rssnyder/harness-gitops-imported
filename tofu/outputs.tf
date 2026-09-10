output "org_id" {
  value = harness_platform_organization.gitops.id
}

output "agent_id" {
  value = harness_platform_gitops_agent.hrns.identifier
}

output "agent_id_qualified" {
  value = local.agent_id_qualified
}

output "in_cluster_id" {
  value = harness_platform_gitops_cluster.in_cluster.identifier
}

output "teams" {
  value = {
    for name, mod in module.team : name => {
      project_id        = mod.project_id
      namespace         = mod.namespace
      argo_project_name = mod.argo_project_name
    }
  }
}

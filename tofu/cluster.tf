# Harness allows a given server URL to be registered as a GitOps Cluster
# only once per agent, so the single physical in-cluster the agent runs in
# is registered exactly once here, at org scope (no project_id - it isn't
# owned by any one team). Namespace isolation between teams is enforced by
# each team's AppProject `destinations` block (see
# modules/team_project/main.tf), not by this cluster entity.
resource "harness_platform_gitops_cluster" "in_cluster" {
  identifier   = "in_cluster"
  org_id       = harness_platform_organization.gitops.id
  agent_id     = local.agent_id_qualified
  force_update = true

  depends_on = [time_sleep.wait_for_gitops_agent]

  request {
    upsert = true

    cluster {
      server = var.in_cluster_server
      name   = "in-cluster"

      config {
        cluster_connection_type = "IN_CLUSTER"
        tls_client_config {
          insecure = false
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      request[0].upsert,
      request[0].cluster[0].config[0].bearer_token,
    ]
  }
}

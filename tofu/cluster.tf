# registered once, at org scope - Harness rejects registering the same server URL more than once per agent.
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

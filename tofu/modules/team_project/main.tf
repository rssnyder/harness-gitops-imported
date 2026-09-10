# each team: own namespace, own Harness project, own Argo CD project scoped to that namespace, mapped 1:1 to the Harness project.

resource "kubernetes_namespace" "this" {
  metadata {
    name = var.team
    labels = {
      "harness.io/team" = var.team
    }
  }
}

resource "harness_platform_project" "this" {
  identifier  = var.team
  name        = var.team
  org_id      = var.org_id
  description = "Team ${var.team} - gitops deploys are confined to the '${var.team}' namespace"
  tags        = ["source:opentofu", "team:${var.team}"]
}

# Argo CD project scoping this team's applications to their namespace only.
resource "harness_platform_gitops_app_project" "this" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.agent_id
  upsert     = true

  project {
    metadata {
      name      = var.team
      namespace = var.agent_namespace
    }

    spec {
      source_repos = ["*"]

      destinations {
        server    = var.in_cluster_server
        namespace = var.team
        name      = var.cluster_name
      }

      # no cluster_resource_whitelist block: empty whitelist blocks all cluster-scoped resources.
      # block quota/network guardrails from being touched by synced manifests.
      namespace_resource_blacklist {
        group = ""
        kind  = "ResourceQuota"
      }
      namespace_resource_blacklist {
        group = ""
        kind  = "LimitRange"
      }
      namespace_resource_blacklist {
        group = "networking.k8s.io"
        kind  = "NetworkPolicy"
      }
    }
  }
}

# ties this Argo project 1:1 to this Harness project - other projects can't reference it.
resource "harness_platform_gitops_app_project_mapping" "this" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.agent_id

  argo_project_name = harness_platform_gitops_app_project.this.project[0].metadata[0].name
}


# each team gets: its own k8s namespace, its own Harness project, and its
# own Argo CD "AppProject" - restricted to deploying only into that
# namespace - registered against the shared org-level agent. the physical
# cluster itself is registered exactly once, at org scope (see
# ../../cluster.tf) - Harness rejects registering the same server URL as a
# GitOps Cluster more than once per agent. isolation between teams is
# therefore enforced entirely by each AppProject's `destinations` (limited
# to that team's namespace) plus the 1:1 app-project-to-harness-project
# mapping below: a user scoped to the "web" Harness project can only
# operate within the "web" Argo project, whose only allowed destination
# namespace is "web".

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

# Argo CD project scoping the team's applications to their namespace only.
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

      # deliberately no cluster_resource_whitelist block: an empty whitelist
      # means no cluster-scoped resources (namespaces are managed by tofu,
      # not argo) can be synced by this project.

      # prevent a team's applications from touching quota/network guardrails
      # in their own namespace via a synced manifest.
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

# ties this Argo project to this Harness project: applications/appsets
# created under other Harness projects cannot reference the "web" (etc)
# Argo project, and vice versa.
resource "harness_platform_gitops_app_project_mapping" "this" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.agent_id

  argo_project_name = harness_platform_gitops_app_project.this.project[0].metadata[0].name
}


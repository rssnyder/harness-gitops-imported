# minimal demo Argo CD application per team, for end-to-end validation of the namespace isolation set up in main.tf.

resource "harness_platform_environment" "demo" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier = "demo"
  name       = "demo"
  type       = "PreProduction"
  tags       = ["source:opentofu"]
}

# links the shared in-cluster into this team's project/environment.
resource "harness_platform_environment_clusters_mapping" "demo" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  env_id     = harness_platform_environment.demo.id
  identifier = "demo"

  clusters {
    identifier       = var.cluster_identifier
    name             = var.cluster_name
    agent_identifier = var.agent_id
    scope            = "ORGANIZATION"
  }
}

# gitops-enabled service reference so the Application shows up against a Harness service/environment pair.
resource "harness_platform_service" "guestbook" {
  org_id     = var.org_id
  project_id = harness_platform_project.this.id

  identifier  = "guestbook"
  name        = "guestbook"
  description = "demo gitops-enabled service for validating team ${var.team}'s namespace isolation"

  yaml = <<-EOT
service:
  name: guestbook
  identifier: guestbook
  orgIdentifier: ${var.org_id}
  projectIdentifier: ${harness_platform_project.this.id}
  gitOpsEnabled: true
  EOT
}

resource "harness_platform_gitops_applications" "guestbook" {
  depends_on = [
    harness_platform_environment_clusters_mapping.demo,
  ]

  org_id     = var.org_id
  project_id = harness_platform_project.this.id
  agent_id   = var.agent_id
  name       = "${var.team}-guestbook"
  cluster_id = var.cluster_identifier
  repo_id    = var.repo_identifier
  project    = harness_platform_gitops_app_project.this.project[0].metadata[0].name
  upsert     = true

  application {
    metadata {
      name      = "${var.team}-guestbook"
      namespace = var.agent_namespace
      labels = {
        "harness.io/serviceRef" = harness_platform_service.guestbook.id
        "harness.io/envRef"     = harness_platform_environment.demo.id
      }
    }

    spec {
      project = harness_platform_gitops_app_project.this.project[0].metadata[0].name

      source {
        repo_url        = var.repo_url
        path            = "guestbook"
        target_revision = "master"
      }

      destination {
        server = var.in_cluster_server
        # namespace already exists; the AppProject's destinations block is what actually confines this.
        namespace = var.team
      }

      sync_policy {
        automated {
          prune     = true
          self_heal = true
        }
      }
    }
  }
}

output "project_id" {
  value = harness_platform_project.this.id
}

output "namespace" {
  value = kubernetes_namespace.this.metadata[0].name
}

output "argo_project_name" {
  value = harness_platform_gitops_app_project.this.project[0].metadata[0].name
}

output "demo_application" {
  value = harness_platform_gitops_applications.guestbook.name
}

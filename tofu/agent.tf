# BYOA agent wrapping the existing argocd install. CONNECTED_ARGO_PROVIDER is deprecated per harness eng - MANAGED_ARGO_PROVIDER is now used for BYOA too (deployment mode is controlled by argo-cd.enabled below, not this type value).
resource "harness_platform_gitops_agent" "hrns" {
  identifier  = var.agent_id
  org_id      = harness_platform_organization.gitops.id
  name        = var.agent_id
  description = "BYOA agent wrapping the pre-existing argocd install in the hrns talos cluster"
  type        = "MANAGED_ARGO_PROVIDER"
  operator    = "ARGO"

  metadata {
    namespace         = var.agent_namespace
    high_availability = false
  }
}

# only the gitops-agent component is installed; argo-cd subchart disabled (BYOA) since argocd is already running here.
resource "helm_release" "gitops_agent" {
  name             = "gitops-agent"
  repository       = "https://harness.github.io/gitops-helm"
  chart            = "gitops-helm"
  namespace        = var.agent_namespace
  create_namespace = false

  values = [yamlencode({
    "argo-cd" = {
      enabled = false
    }

    agent = {
      # tolerate the control-plane's stuck proxmox-ccm taint, same as the existing argocd pods.
      tolerations = [
        {
          key      = "node.cloudprovider.kubernetes.io/uninitialized"
          operator = "Exists"
          effect   = "NoSchedule"
        }
      ]
    }

    harness = {
      identity = {
        accountIdentifier = data.harness_platform_current_account.current.account_id
        orgIdentifier     = harness_platform_organization.gitops.id
        agentIdentifier   = harness_platform_gitops_agent.hrns.identifier
      }
      secrets = {
        agentSecret = harness_platform_gitops_agent.hrns.agent_token
      }
      configMap = {
        http = {
          agentHttpTarget = var.gitops_http_target
        }
      }
      # networkpolicy templates reference the disabled argo-cd subchart's helpers, so disable.
      networkPolicy = {
        create = false
      }
    }
  })]
}

# give the agent time to register with harness before anything else attaches to it.
resource "time_sleep" "wait_for_gitops_agent" {
  depends_on      = [helm_release.gitops_agent]
  create_duration = "60s"
}

locals {
  # scope-prefixed identifiers required by downstream harness_platform_gitops_* resources.
  agent_id_qualified   = harness_platform_gitops_agent.hrns.prefixed_identifier
  cluster_id_qualified = "org.${harness_platform_gitops_cluster.in_cluster.identifier}"
  repo_id_qualified    = "org.${harness_platform_gitops_repository.guestbook.identifier}"
}

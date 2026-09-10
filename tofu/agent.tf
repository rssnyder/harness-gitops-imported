# "import" here means: register a Harness GitOps agent of type
# CONNECTED_ARGO_PROVIDER (Harness calls this BYOA - "bring your own argo")
# against the argocd install that is already running in the cluster
# (namespace "argocd", stock upstream argo-cd helm chart, confirmed via the
# hrns.kubeconfig cluster), instead of having Harness deploy/manage a fresh
# argocd stack of its own (that would be type MANAGED_ARGO_PROVIDER, which
# provisions its own argo-cd subchart).
resource "harness_platform_gitops_agent" "hrns" {
  identifier  = var.agent_id
  org_id      = harness_platform_organization.gitops.id
  name        = var.agent_id
  description = "BYOA agent wrapping the pre-existing argocd install in the hrns talos cluster"
  type        = "CONNECTED_ARGO_PROVIDER"
  operator    = "ARGO"

  metadata {
    namespace         = var.agent_namespace
    high_availability = false
  }
}

# only the harness gitops-agent component is installed here - the argo-cd
# subchart is disabled (argo-cd.enabled = false is the chart's documented
# "BYOA" flow, see gitops-helm's values.yaml) since a full argocd stack is
# already running in this namespace. the agent's default service name
# overrides (argocd-repo-server, argocd-redis, argocd-application-controller,
# argocd-applicationset-controller) already match the existing install's
# object names one-for-one, so no name overrides are needed here.
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
      # the cluster's proxmox cloud-controller-manager never clears this
      # taint on the (single, control-plane) node - the existing argocd
      # pods already tolerate it, match that so the agent can schedule.
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
      networkPolicy = {
        # the gitops-helm chart's networkpolicy templates reference named
        # templates defined by the argo-cd subchart, which isn't loaded
        # when argo-cd.enabled = false (BYOA) - disable to avoid a broken
        # template lookup.
        create = false
      }
    }
  })]
}

# give the agent time to register/connect to the harness control plane
# before any project/cluster/app-project resources try to attach to it.
resource "time_sleep" "wait_for_gitops_agent" {
  depends_on      = [helm_release.gitops_agent]
  create_duration = "60s"
}

locals {
  # fully-qualified, scope-prefixed agent id (e.g. "org.hrns_argocd"), as
  # required by every downstream harness_platform_gitops_* resource's
  # agent_id argument. the provider computes/returns this directly rather
  # than us having to guess the prefixing scheme.
  agent_id_qualified = harness_platform_gitops_agent.hrns.prefixed_identifier

  # org-scoped GitOps clusters/repositories/applications aren't returned by
  # scope-prefixed read-only attributes the way the agent is, but empirically
  # use the same "org.<identifier>" convention when referenced (via
  # cluster_id/repo_id) from a project-scoped resource like an Application.
  cluster_id_qualified = "org.${harness_platform_gitops_cluster.in_cluster.identifier}"
  repo_id_qualified    = "org.${harness_platform_gitops_repository.guestbook.identifier}"
}

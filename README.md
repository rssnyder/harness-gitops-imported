# harness-gitops-imported

Imports an already-running Argo CD install (in `hrns.kubeconfig`, namespace
`argocd`) into Harness CD as an org-level GitOps agent, then provisions
per-team Harness projects (`web`, `backend`, `database`) each scoped to
their own Kubernetes namespace. Pure OpenTofu; the only in-cluster changes
(the harness gitops-agent component + example namespaces) are applied via
the `helm` and `kubernetes` providers.

## Architecture

```
org: gitops
  gitops agent "hrns_argocd" (MANAGED_ARGO_PROVIDER / BYOA)
    -> wraps the pre-existing argocd install in ns "argocd"
       (only the harness "gitops-agent" component from the gitops-helm
        chart is installed; argo-cd.enabled=false so the existing argocd
        stack is left alone)

  gitops cluster "in_cluster" (org-scoped, IN_CLUSTER auth, shared)
  gitops repository "guestbook" (org-scoped, shared, read-only demo repo:
    github.com/argoproj/argocd-example-apps)

  project: web        project: backend      project: database
    namespace: web       namespace: backend    namespace: database
    argo project "web"   argo project "backend" argo project "database"
      destination: {server: in-cluster, namespace: <team>}
    app_project_mapping: argo project <-> harness project (1:1)
    environment "demo" -> environment_clusters_mapping -> in_cluster
    service "guestbook" (gitOpsEnabled)
    application "<team>-guestbook" (guestbook chart, synced into <team> ns)
```

Harness disallows registering the same GitOps cluster server URL, or the
same GitOps repository URL, more than once per agent - so both the shared
in-cluster and the demo repository are registered exactly once, at org
scope, and referenced by every team project's Application using the
scope-prefixed form (`org.<identifier>`, discovered empirically - the API
rejects a project-scoped lookup of an org-scoped cluster/repo by bare
identifier).

### Why a user in one project can only deploy to their namespace

Three layers, each independently sufficient in normal operation, stacked for
defense in depth:

1. **Harness project scope.** All GitOps entities (Argo project, cluster,
   applications/appsets) are created with `project_id = <team>`. A user
   without a role assignment on the `web` project cannot see or mutate
   anything scoped to it, per Harness NextGen RBAC.
2. **Argo CD project mapping.** `harness_platform_gitops_app_project_mapping`
   ties the Argo CD project named `web` to the Harness project `web` only.
   Even an admin working inside the `backend` Harness project cannot create
   an Application that references the `web` Argo project.
3. **Namespace-scoped AppProject destinations.** Every team's Argo CD
   `AppProject` (`harness_platform_gitops_app_project`) declares exactly one
   `destinations` entry: the shared in-cluster, restricted to that team's own
   namespace. Argo CD validates every Application's destination against its
   project's `destinations` at admission/sync time - independent of who
   submitted the Application/AppSet - so even a manually-crafted Application
   inside the `backend` Argo project cannot target the `web` namespace.

## Demo application

Each team project gets a minimal, self-contained Argo CD `Application`
(`modules/team_project/demo.tf`) to validate the wiring end-to-end:
Harness project -> Argo project/mapping -> environment/cluster mapping ->
service -> application -> synced into that team's namespace only. It
deploys the well-known `guestbook` example from
`github.com/argoproj/argocd-example-apps` (public, read-only, no git
credentials required) into `<team>`'s namespace, named `<team>-guestbook`.

```sh
tofu output teams
```

```sh
export KUBECONFIG=../hrns.kubeconfig
kubectl -n argocd get applications.argoproj.io | grep guestbook
kubectl -n web get pods       # guestbook-ui, nowhere else
```

Note: in this lab cluster, `guestbook-ui`'s pod may sit `Pending` because of
a pre-existing, unrelated `node.cloudprovider.kubernetes.io/uninitialized`
taint that the proxmox cloud-controller-manager never clears (see the
toleration added to the harness gitops-agent's own pod in `agent.tf` for the
same issue) - the Application still reports `Synced`, which is what
matters for validating the GitOps wiring itself.

## Usage

```sh
source ./scripts/load-env.sh   # exports HARNESS_ACCOUNT_ID / HARNESS_PLATFORM_API_KEY
cd tofu
tofu init
tofu plan
tofu apply
```

`hrns.kubeconfig` is referenced relatively (`../hrns.kubeconfig`) by the
`helm`/`kubernetes` providers - run tofu from the `tofu/` directory.

## Layout

- `tofu/providers.tf`, `variables.tf`, `main.tf` - provider config + shared data sources
- `tofu/org.tf` - the `gitops` organization
- `tofu/agent.tf` - imports the existing argocd install as a Harness GitOps agent (BYOA)
- `tofu/cluster.tf` - the shared, org-scoped in-cluster GitOps cluster entity
- `tofu/repository.tf` - the shared, org-scoped demo GitOps repository entity
- `tofu/teams.tf` - one `team_project` module instance per example team
- `tofu/modules/team_project` - namespace + Harness project + Argo CD project + app-project mapping + environment + demo application for one team

In this project we have ./.env which has credentials to a harness account, and ./hrns.kubeconfig which is a kubeconfig to a local k8s cluster built on talos with an existing argocd agent deployed

goal: define a pattern using pure opentofu to import an existing argo agent to harness cd at the organization level, which then creates (via harness) argo projects scoped to individual team namespaces, which map to harness projects for teams

important: we need to structure the harness resources such that a user in one project can only deploy to their namespace

guidance: create a new org "gitops" where the agent is imported, and projects for each example team "web" "backend" "database"

requirements: everything is as code, opentofu when at all possible, if we have to create resources in the cluster do so via the kubernetes or helm provider, preferr helm

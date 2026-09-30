# Architecture

How this repository is put together, and why. For day-to-day commands see
[README.md](README.md); for how packets and requests actually move see
[TRAFFIC_FLOW.md](TRAFFIC_FLOW.md).

## Three stacks, three lifecycles

The repository is not one Terraform configuration. It is three, each with its
own state file and its own reason to change.

```
backend/          →   gitlab/            →   env/dev/
remote state          pipeline identity      the workload
(local state)         (remote state)         (remote state)
applied once          applied by a human     applied by CI
```

The split exists because these things change at different rates and carry
different risk. State infrastructure is created once and then left alone. The
pipeline identity changes when permissions change, and a mistake there locks the
pipeline out of Azure. The workload changes daily.

Two consequences follow from the split, and both have caused real failures:

- **`backend/` cannot use a remote backend**, because it is the thing that
  creates one. Its state is a local file, which must be backed up: it is the
  only record of the state storage account.
- **`gitlab/` is never applied by CI.** It owns the identity that grants the
  pipeline its access, so a pipeline that could rewrite it could grant itself
  anything. This makes changes to `gitlab/*.tf` a three-step operation — edit,
  commit, *and* apply by hand. Nothing warns you if you skip the third step;
  the code and reality simply disagree until someone notices.

## Trust model

No Azure credential is stored in GitLab or in this repository. Authentication
uses OpenID Connect workload identity federation:

1. GitLab mints a short-lived JWT for the job, with an audience this repo
   controls.
2. Entra ID compares the token's `iss`, `aud`, and `sub` claims against a
   federated identity credential attached to the `gitlab-app` registration.
3. On an exact match it issues an access token for the service principal.
4. The service principal can do exactly what its RBAC role assignments allow.

The matching is an exact string comparison, with no wildcards. This is the
model's main sharp edge: the credential's subject pins a single branch, so only
pipelines on the default branch can authenticate at all. The `validate` job
sidesteps this by running `terraform init -backend=false`, which touches nothing
in Azure and therefore works on any branch.

The service principal holds two role assignments: Contributor at subscription
scope, and Storage Blob Data Contributor on the state storage account. The
subscription-wide grant exists because the workload modules create their own
resource groups — creating a resource group is a subscription-level operation
and cannot be scoped to a group that does not yet exist. Pre-creating the
resource groups in `backend/` and narrowing Contributor to each would be the
least-privilege alternative.

## Resource topology

Two resource groups hold the dev workload, plus a third for state.

| Resource group | Created by | Contents |
|----------------|------------|----------|
| `cicdprojectdev-rg` | `backend/` | State storage account and `tfstate` container |
| `cicd-resource-group` | `modules/networking` | VNet, four subnets, Bastion public IP |
| `compute-rg` | `modules/compute` | VM, NIC, Bastion host |

The network lives in one resource group and the machines in another. This works
— a NIC can reference a subnet in a different resource group — but it means two
resource groups to keep in step and, under a least-privilege model, two role
assignments. Placing both in one resource group would remove that.

### Network

A single `/16` VNet carved into four `/24` subnets:

| Subnet | Prefix | Purpose |
|--------|--------|---------|
| `cicd-subnet` | `10.0.1.0/24` | web tier |
| `cicd-app-subnet` | `10.0.2.0/24` | application tier |
| `cicd-db-subnet` | `10.0.3.0/24` | database tier |
| `AzureBastionSubnet` | `10.0.4.0/24` | Azure Bastion (name is mandatory) |

There are currently **no network security groups**. Subnets are tiered by
intent, not yet by enforcement — every subnet can reach every other, because
that is the VNet default. Adding NSGs is what would turn the tiering into a real
boundary, and is the obvious next piece of `modules/security`.

### Compute

One Ubuntu 22.04 LTS Gen2 VM (`Standard_D2als_v6`), SSH key authentication only,
password auth explicitly disabled, and no public IP. Access is via Azure Bastion.

Two constraints drove the sizing, and they interact: this subscription cannot
use the older families (`Standard_DS1_v2`, the whole B-series and `D_v3` are all
`NotAvailableForSubscription`), and the v6 families that *are* available are
Hyper-V Generation 2 only. That is why the image sku is `22_04-lts-gen2` rather
than `22_04-lts` — a Gen1 image will not boot on a Gen2-only size.

## Module interfaces

`networking` exposes `subnet_ids` as a **positional list**, and `compute`
indexes into it:

```
subnet_ids[0]  cicd-subnet          (web)
subnet_ids[1]  cicd-db-subnet       (database)   ← the VM NIC lands here
subnet_ids[2]  cicd-app-subnet      (app)
subnet_ids[3]  AzureBastionSubnet               ← the Bastion host
```

Positional indexing is fragile: the meaning of every index changes if a subnet
is inserted or reordered in `outputs.tf`, silently and with no error. Returning
a **map keyed by name** (`subnet_ids["app"]`) would make the wiring explicit and
reorder-proof. Worth noting that the VM currently sits in the *database* subnet,
which is consistent with the code but probably not with the intent.

## Environments

Only `env/dev` is built. `env/stage` and `env/prod` exist as directories of
empty files, and `modules/database` and `modules/security` likewise. A new
environment needs its own `backend.tf` with a distinct state `key` — never share
a state file between environments — its own `.auto.tfvars`, and its own role
assignments.

## Design decisions, restated

| Decision | Why | Cost |
|----------|-----|------|
| Three stacks, separate state | Isolates blast radius; identity changes cannot be made by the pipeline | Two-phase applies that nothing enforces |
| OIDC federation over a stored secret | Nothing to leak, nothing to rotate | Exact-match subject pins one branch |
| Manual gate on `apply` | A human reads the plan before infrastructure changes | Deploys are not fully automatic |
| Plan carried as an artifact | `apply` runs exactly what was reviewed | Plans go stale; a re-plan is required after any state change |
| SSH key over password | Public key is not a secret, so it lives in committed tfvars | Key management moves to the operator |
| Bastion, no public IP on the VM | No SSH port exposed to the internet | Bastion is a standing cost |

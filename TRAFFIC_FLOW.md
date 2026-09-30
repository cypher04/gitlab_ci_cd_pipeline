# Traffic Flow

Two separate flows run through this system, and they share almost nothing. The
**control plane** is how a code change becomes deployed infrastructure. The
**data plane** is how packets move once that infrastructure exists.

For the reasoning behind the design see [ARCHITECTURE.md](ARCHITECTURE.md).

---

## 1. Control plane — a change reaching Azure

```
 developer                GitLab                     Entra ID              Azure
 ─────────                ──────                     ────────              ─────

  git push  ──────────▶  pipeline starts
                              │
                         ┌────▼─────┐
                         │ validate │  fmt / init -backend=false / validate
                         └────┬─────┘  no Azure access — runs on any branch
                              │
                     default branch only
                              │
                         ┌────▼─────┐   OIDC id_token
                         │   plan   │ ─────────────────▶ verify iss/aud/sub
                         └────┬─────┘                          │
                              │                          access token
                              │                                │
                              │   ◀────────────────────────────┘
                              │
                              ├── read state ──────────────▶ tfstate blob
                              ├── read resources ──────────▶ Azure Resource Manager
                              └── writes tfplan artifact
                              │
                    ┌─────────▼─────────┐
                    │  apply  (manual)  │  a human presses play
                    └─────────┬─────────┘
                              │
                              ├── create / update ─────────▶ Azure Resource Manager
                              └── write state ─────────────▶ tfstate blob
```

**What crosses each boundary**

| Hop | Carries | Notes |
|-----|---------|-------|
| Runner → Entra ID | OIDC JWT | Short-lived, minted per job, audience must match the federated credential |
| Entra ID → Runner | Access token | Issued only on an exact `iss`/`aud`/`sub` match |
| Runner → ARM | Resource reads and writes | Scoped by the service principal's RBAC |
| Runner → Blob storage | State read and write | Requires Storage Blob Data Contributor; holds a lease for the duration |
| `plan` → `apply` | `tfplan` artifact | So `apply` executes exactly what was reviewed |

**Where it breaks, and how it looks**

- Job runs on a non-default branch → the `sub` claim does not match →
  `AADSTS700213`. Only `validate` is designed to work there.
- CI/CD variables are protected, so on an unprotected ref they arrive empty.
  Terraform then finds no OIDC configuration, falls through its authentication
  chain to the Azure CLI, and reports that `az` is not installed — which is a
  symptom, never the cause.
- A cancelled job can leave the state lease held; the next run fails to acquire
  the lock until it is broken.

---

## 2. Data plane — reaching and running the VM

```
                    internet
                        │
                        │  HTTPS 443 (Azure portal)
                        ▼
              ┌───────────────────┐
              │  Bastion public   │   Standard, static
              │  IP               │
              └─────────┬─────────┘
                        │
  cicd-resource-group   │            compute-rg
  ┌─────────────────────┼──────────────────────────────────┐
  │  VNet  10.0.0.0/16  │                                  │
  │                     ▼                                  │
  │   ┌────────────────────────────┐                       │
  │   │ AzureBastionSubnet         │   ┌────────────────┐  │
  │   │ 10.0.4.0/24                │──▶│ Bastion host   │  │
  │   └────────────────────────────┘   └───────┬────────┘  │
  │                                            │ SSH 22    │
  │   ┌────────────────────────────┐           │ (private) │
  │   │ cicd-db-subnet 10.0.3.0/24 │◀──────────┘           │
  │   │   infra-vm-nic → infra-vm  │                       │
  │   └────────────────────────────┘                       │
  │                                                        │
  │   ┌────────────────────────────┐                       │
  │   │ cicd-subnet    10.0.1.0/24 │  web tier   (empty)   │
  │   ├────────────────────────────┤                       │
  │   │ cicd-app-subnet 10.0.2.0/24│  app tier   (empty)   │
  │   └────────────────────────────┘                       │
  └────────────────────────────────────────────────────────┘
                        │
                        │  outbound (Azure default egress)
                        ▼
                    internet
```

**Inbound.** There is exactly one way in. The VM has **no public IP**, so no SSH
port is exposed to the internet. An operator opens the VM in the Azure portal,
which connects over HTTPS to the Bastion public IP; the Bastion host then opens
a private SSH session to the VM's NIC inside the VNet. Authentication is by SSH
key only — `disable_password_authentication = true`, and no password is set.

**East–west.** All four subnets sit in one VNet with **no network security
groups**, so the Azure default applies: any subnet can reach any other on any
port. The tiering is naming and intent, not enforcement. Until NSGs exist, a
compromise in one tier has an unobstructed path to the rest.

**Outbound.** The VM has no public IP, no NAT gateway, and no load balancer, so
it reaches the internet through Azure's implicit default outbound access. That
path is adequate for package updates but has no stable egress address, and
Microsoft is retiring it for new deployments — an explicit NAT gateway is the
durable replacement.

---

## Known gaps

| Gap | Effect |
|-----|--------|
| No network security groups | Tier boundaries are advisory; all intra-VNet traffic is permitted |
| VM sits in `cicd-db-subnet` | `compute` takes `subnet_ids[1]`, which is the database subnet — consistent with the code, likely not with the intent |
| No NAT gateway | Outbound depends on default egress, which has no fixed IP and is being retired |
| Web and app subnets empty | Nothing is deployed into them yet |
| No private endpoints | State storage is reached over its public endpoint, protected by RBAC rather than network isolation |

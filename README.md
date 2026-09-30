# GitLab CI/CD Pipeline for Azure Infrastructure

Terraform infrastructure for Azure, deployed by a GitLab CI/CD pipeline that
authenticates with **workload identity federation** — no Azure credentials are
stored in GitLab or in this repository.

The repo is split into three Terraform stacks with separate state. Two are
bootstrapped by hand; the third is what the pipeline deploys.

## Stacks and apply order

Order matters — each stack depends on the one above it existing.

| # | Path | Creates | State | Applied by |
|---|------|---------|-------|------------|
| 1 | `backend/` | Resource group, storage account and `tfstate` container that hold remote state | Local file | Human, once |
| 2 | `gitlab/` | Entra ID app registration, service principal, federated credential, RBAC role assignments, GitLab environment, branch protection, CI/CD variables | `gitlab-terraform.tfstate` | Human, on identity changes |
| 3 | `env/dev/` | The workload — networking and compute | `terraform.tfstate` | The pipeline |

`backend/` keeps its state in a local file on purpose: it *creates* the remote
backend, so it cannot use one. Back that file up — it is gitignored and is the
only record of the state infrastructure.

The `gitlab/` stack is deliberately never applied by CI. It owns the identity
that grants the pipeline its access, so letting the pipeline rewrite it would be
circular. **A change to `gitlab/*.tf` only takes effect when a human applies it.**

## Prerequisites

- **Terraform** — CI runs `1.9.8`; use 1.9 or newer locally
- **Azure CLI** — for the initial sign-in; providers pinned to `azurerm ~> 4.80`
- **Azure permissions** — ability to create Entra ID app registrations and assign
  RBAC roles at subscription scope
- **A GitLab project** — `gitlab.tf` reads it with a `data` source; it does not
  create it
- **A GitLab personal access token** with `api` scope, for the bootstrap stack

## First-time setup

```bash
# 1. sign in and select the subscription
az login --tenant <tenant-id>
az account set --subscription <subscription-id>

# 2. create the remote state backend
terraform -chdir=backend init
terraform -chdir=backend apply

# 3. create the pipeline identity and GitLab configuration
export TF_VAR_gitlab_token='<gitlab-pat>'
terraform -chdir=gitlab init
terraform -chdir=gitlab apply

# 4. confirm the federated credential matches what GitLab will send
APP_ID=$(az ad app list --display-name gitlab-app --query "[0].id" -o tsv)
az ad app federated-credential list --id "$APP_ID" -o jsonc
```

Secrets are passed through the environment, never through a committed file.
`*.tfvars` is gitignored, with one deliberate exception: `env/*/*.auto.tfvars`,
which carries non-secret values (region, CIDRs, SSH **public** key) that CI needs.

## Day-to-day

A change ships through the pipeline, defined in `.gitlab-ci.yml`:

| Stage | Runs on | Trigger | What it does |
|-------|---------|---------|--------------|
| `validate` | any branch, any MR | automatic | `fmt -check`, `init -backend=false`, `validate` — no Azure access needed |
| `plan` | default branch | automatic | authenticates via OIDC, plans against real state, saves `tfplan` as an artifact |
| `apply` | default branch | **manual** | applies the exact plan artifact from `plan` |
| `destroy` | default branch | **manual** | tears the environment down |

1. Branch, edit, run `terraform fmt -recursive`, open a merge request.
2. `validate` runs on the MR.
3. On merge, `plan` runs and prints the full plan into the job log. **Read it.**
4. Release `apply` by hand if the plan is what you intended.

`apply` and `destroy` share a `resource_group` mutex so two runs can never touch
the state file at once.

## Repository layout

```
backend/        remote state bootstrap (local state)
gitlab/         pipeline identity, RBAC, GitLab project config
env/dev/        the deployed dev environment
env/stage/      scaffold — files exist but are empty
env/prod/       scaffold — files exist but are empty
modules/
  networking/   resource group, VNet, web/app/db/bastion subnets, bastion public IP
  compute/      resource group, NIC, Ubuntu 22.04 Linux VM (SSH key auth)
  database/     not yet implemented
  security/     not yet implemented
```

## Authentication

GitLab mints a short-lived OIDC token for each job. Entra ID exchanges it for an
access token only if the token's `sub` claim matches the federated credential
exactly, and the resulting service principal holds only the RBAC it was granted.

Two consequences worth knowing:

- The credential's subject is pinned to the default branch, so only pipelines on
  that branch can authenticate. `validate` works anywhere because it runs with
  `-backend=false` and needs no Azure access.
- CI/CD variables are **protected**, so they are injected only on protected
  branches and tags. On any other ref they arrive as empty strings, which
  surfaces as a confusing authentication error rather than a missing-value one.

## State

Remote state lives in the storage account created by `backend/`, with blob
versioning and a 30-day soft-delete window. If a run is cancelled mid-operation
the lease can be left held:

```bash
terraform -chdir=env/dev force-unlock <LOCK_ID>
```

Confirm no pipeline job is still running first.

## Status

`env/dev` is the only environment built out. `env/stage` and `env/prod` contain
empty placeholder files, and the `database` and `security` modules are likewise
unimplemented. Treat them as not yet available.

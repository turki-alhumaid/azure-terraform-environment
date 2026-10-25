# Azure environment with Terraform

Terraform for a fictional company's Azure environment: networking, VMs, governance and CI, split into dev and prod.

## Overview

This repository builds the Azure environment for **az-infra**, a fictional company. Two environments, dev and prod, are built from the same three modules: `network`, `compute` and `governance`. Dev is applied, verified and destroyed after every session; prod is validated and planned but never applied.

The project runs on an **Azure for Students** subscription, which shapes several decisions: one region (`indiasouthcentral`), a 6-vCPU quota that fits exactly three small VMs, and a hard credit limit instead of a monthly bill.

## Architecture

Three Ubuntu VMs sit in three subnets of one virtual network. Only the jump VM is reachable from the internet, and only over SSH from the administrator's IP address. Inside the network, only three paths are open: jump to app and data over SSH, and app to data over PostgreSQL.

Names in this section are for dev. Prod uses the same names with `prod` in place of `dev`.

**Network and traffic**

```
                            Internet
                                |
                     SSH :22, admin IP only
                                v
+---------------------------------------------------------------+
| vnet-az-infra-dev-core  10.10.0.0/16                          |
|                                                               |
|  +---------------------------------------------------------+  |
|  | snet-az-infra-dev-jump  10.10.1.0/24                    |  |
|  | vm-az-infra-dev-jump + public IP                        |  |
|  | fail2ban                                                |  |
|  +---------------------------------------------------------+  |
|               |                                |              |
|            SSH :22                          SSH :22           |
|               v                                v              |
|  +------------------------+       +------------------------+  |
|  | snet-az-infra-dev-app  |       | snet-az-infra-dev-data |  |
|  | 10.10.2.0/24           |       | 10.10.3.0/24           |  |
|  | vm-az-infra-dev-app    |-5432->| vm-az-infra-dev-data   |  |
|  | nginx                  |       | postgresql             |  |
|  +------------------------+       +------------------------+  |
|                                                               |
| Each subnet has its own NSG. All other traffic inside         |
| the VNet is denied.                                           |
+---------------------------------------------------------------+
```

<details>
<summary><b>Show every resource, grouped by scope</b></summary>

**Resources by scope**

```
Subscription (Azure for Students)
|
+-- Policy assignments (subscription scope)
|     pa-az-infra-dev-locations-resources
|     pa-az-infra-dev-locations-resource-groups
|     pa-az-infra-dev-require-tag-environment
|     pa-az-infra-dev-require-tag-managed_by
|
+-- rg-az-infra-dev-network
|     vnet-az-infra-dev-core
|     snet-az-infra-dev-jump, snet-az-infra-dev-app, snet-az-infra-dev-data
|     nsg-az-infra-dev-jump, nsg-az-infra-dev-app, nsg-az-infra-dev-data
|
+-- rg-az-infra-dev-compute
|     pip-az-infra-dev-jump
|     vm-az-infra-dev-jump    nic-az-infra-dev-jump    osdisk-az-infra-dev-jump
|     vm-az-infra-dev-app     nic-az-infra-dev-app     osdisk-az-infra-dev-app
|     vm-az-infra-dev-data    nic-az-infra-dev-data    osdisk-az-infra-dev-data
|     (each NIC connects to its subnet in rg-az-infra-dev-network)
|
+-- rg-az-infra-tfstate (bootstrap script, not Terraform)
      stazinfratfstate2424 > container tfstate > dev / prod state files

Entra ID tenant
+-- grp-az-infra-dev-netops    Network Contributor on rg-az-infra-dev-network
+-- grp-az-infra-dev-appops    Virtual Machine Contributor on rg-az-infra-dev-compute
+-- grp-az-infra-dev-auditors  Reader on the subscription
```

Dev is shown. Prod is identical, with `prod` in the names and `10.20.0.0/16` as the address space.

</details>

### Virtual machines

| VM | Subnet | Public IP | Installed by cloud-init |
|---|---|---|---|
| `vm-az-infra-dev-jump` | jump | Yes (static) | fail2ban |
| `vm-az-infra-dev-app` | app | No | nginx |
| `vm-az-infra-dev-data` | data | No | PostgreSQL, listening on all interfaces (the NSG limits it to the app subnet) |

All three run Ubuntu 24.04 LTS on `Standard_B2ats_v2` (2 vCPUs each), accept SSH keys only, and write their role to `/etc/az-infra-role`.

### Network security

Each subnet has its own network security group (NSG). Azure's built-in rules already block inbound internet traffic, but they allow all traffic inside the VNet at priority 65000. The `deny-vnet-inbound` rule at priority 4000 overrides that, so only the paths in this table work.

| NSG | Rule | Priority | Source | Port | Action |
|---|---|---|---|---|---|
| jump | `allow-ssh-admin` | 100 | Admin IP (`/32`) | 22 | Allow |
| app | `allow-ssh-from-jump` | 100 | jump subnet | 22 | Allow |
| data | `allow-ssh-from-jump` | 100 | jump subnet | 22 | Allow |
| data | `allow-postgres-from-app` | 110 | app subnet | 5432 | Allow |
| all three | `deny-vnet-inbound` | 4000 | VirtualNetwork | Any | Deny |

The admin IP never appears in the code. It's passed at run time through the `TF_VAR_admin_source_cidr` environment variable.

### Resource groups

| Resource group | Contains | Managed by |
|---|---|---|
| `rg-az-infra-dev-network` | VNet, 3 subnets, 3 NSGs and their rules | Terraform |
| `rg-az-infra-dev-compute` | Jump public IP, 3 NICs, 3 VMs, 3 OS disks | Terraform |
| `rg-az-infra-tfstate` | Storage account and container for Terraform state | Bootstrap script, never destroyed |
| `NetworkWatcherRG` | Network Watcher | Azure (created automatically with the first VNet) |

### Governance

Four policy assignments apply at subscription scope:

| Assignment | Built-in policy | Effect |
|---|---|---|
| `pa-az-infra-dev-locations-resources` | Allowed locations | Denies resources outside `indiasouthcentral` |
| `pa-az-infra-dev-locations-resource-groups` | Allowed locations for resource groups | Denies resource groups outside `indiasouthcentral` |
| `pa-az-infra-dev-require-tag-environment` | Require a tag on resource groups | Denies resource groups without an `environment` tag |
| `pa-az-infra-dev-require-tag-managed_by` | Require a tag on resource groups | Denies resource groups without a `managed_by` tag |

Terraform assigns roles to Entra ID groups, not to individual users:

| Entra ID group | Role | Scope |
|---|---|---|
| `grp-az-infra-dev-netops` | Network Contributor | `rg-az-infra-dev-network` |
| `grp-az-infra-dev-appops` | Virtual Machine Contributor | `rg-az-infra-dev-compute` |
| `grp-az-infra-dev-auditors` | Reader | Subscription |

The groups are created empty; membership is managed outside Terraform.

Every taggable resource gets five tags: `company_name`, `environment`, `managed_by` (always `terraform`), plus `owner` and `cost_center` from each environment's `terraform.tfvars`. The three core tags are merged last, so tfvars values can't override them.

### Environments

| | dev | prod |
|---|---|---|
| Root folder | `environments/dev` | `environments/prod` |
| Name prefix | `az-infra-dev` | `az-infra-prod` |
| VNet | `10.10.0.0/16` | `10.20.0.0/16` |
| Subnets (jump, app, data) | `10.10.1.0/24`, `10.10.2.0/24`, `10.10.3.0/24` | `10.20.1.0/24`, `10.20.2.0/24`, `10.20.3.0/24` |
| State file | `dev.terraform.tfstate` | `prod.terraform.tfstate` |
| SSH key | `~/.ssh/az-infra-dev.pub` | `~/.ssh/az-infra-prod.pub` |
| `cost_center` tag | `cc-1001` | `cc-2001` |
| Status | Applied, verified, destroyed after every session | Plan-only (36 resources to add), never applied |

## CI

Every push and pull request runs these checks on a fresh Ubuntu machine ([workflow](.github/workflows/ci.yaml)):

| Check | Command | Catches |
|---|---|---|
| Formatting | `terraform fmt -check -recursive` | Code not in standard Terraform format |
| Validation (dev and prod) | `terraform init -backend=false`, then `terraform validate` | Syntax errors, wrong types, broken references |
| Linting | `tflint --recursive` with the `terraform` and `azurerm` rulesets | Missing version constraints, unused declarations, invalid Azure values |

CI has no Azure credentials. It never connects to the state storage and never runs `plan` or `apply`. Terraform and TFLint versions are pinned so CI behaves the same as a local machine.

TFLint reads `terraform.tfvars`, which points `file()` at an SSH public key, so CI generates throwaway keys at the expected paths before linting. The keys exist only for that run; real keys never leave `~/.ssh`.

To run the same checks locally, from the repository root:

```powershell
terraform fmt -check -recursive
tflint --init
tflint --recursive --config "$PWD\.tflint.hcl"
```

## Repository structure

<details>
<summary><b>Show file tree</b></summary>

```
azure-terraform-environment/
├── .github/
│   └── workflows/
│       └── ci.yaml                 # CI: fmt, validate, tflint
├── bootstrap/
│   └── remote-state-storage.ps1    # one-time setup of the state storage
├── environments/
│   ├── dev/                        # applied and verified
│   │   ├── .terraform.lock.hcl     # locked provider versions
│   │   ├── backend.tf              # remote state location
│   │   ├── locals.tf               # name prefix, common tags, VM image
│   │   ├── main.tf                 # resource groups and module calls
│   │   ├── outputs.tf              # jump public IP, private IPs, admin username
│   │   ├── providers.tf            # Terraform and provider versions
│   │   ├── terraform.tfvars        # values for this environment
│   │   └── variables.tf            # input variables
│   └── prod/                       # plan-only; same roles as the dev files
│       ├── .terraform.lock.hcl
│       ├── backend.tf
│       ├── locals.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── providers.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── modules/
│   ├── compute/
│   │   ├── cloud-init/
│   │   │   ├── app.yaml            # installs nginx
│   │   │   ├── data.yaml           # installs PostgreSQL
│   │   │   └── jump.yaml           # installs fail2ban
│   │   ├── main.tf                 # public IP, NICs, VMs
│   │   ├── outputs.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   ├── governance/
│   │   ├── main.tf                 # policies, Entra ID groups, role assignments
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── network/
│       ├── main.tf                 # VNet, subnets, NSGs
│       ├── nsg_rules.tf            # NSG rules
│       ├── outputs.tf
│       ├── variables.tf
│       └── versions.tf
├── scripts/
│   └── new-ssh-config.ps1          # SSH config from Terraform outputs (dev only)
├── .gitignore
├── .tflint.hcl                     # TFLint rulesets
├── LICENSE
└── README.md
```

</details>

| Module | Creates |
|---|---|
| `modules/network` | VNet, subnets, NSGs, NSG rules, NSG-to-subnet associations |
| `modules/compute` | Jump public IP, NICs, Linux VMs with cloud-init |
| `modules/governance` | Policy assignments, Entra ID groups, role assignments |

## How to run

Requires Azure CLI, Terraform 1.9 or later, and an account that is Owner on the subscription and can create Entra ID groups. Commands are PowerShell, run from the repository root.

```powershell
# 1. Log in and create the state storage (once)
az login
.\bootstrap\remote-state-storage.ps1

# 2. Create an SSH key and allow your public IP
ssh-keygen -t rsa -b 4096 -f "$HOME\.ssh\az-infra-dev"
$ip = Invoke-RestMethod https://api.ipify.org
$env:TF_VAR_admin_source_cidr = "$ip/32"

# 3. Deploy dev (expect 36 resources)
cd environments\dev
terraform init
terraform plan
terraform apply
cd ..\..

# 4. Connect
.\scripts\new-ssh-config.ps1
ssh -F "$HOME\.ssh\az-infra-dev.config" az-jump   # or az-app, az-data

# 5. Destroy
cd environments\dev
terraform destroy
```

- Storage account names are globally unique. To use your own, change `stazinfratfstate2424` in `bootstrap/remote-state-storage.ps1` and both `backend.tf` files.
- `TF_VAR_admin_source_cidr` must be set again in every new PowerShell window.
- If PowerShell blocks the `.ps1` scripts, run `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` once.
- Prod is plan-only: create `~/.ssh/az-infra-prod`, then run `terraform init` and `terraform plan` in `environments\prod`. Don't apply it.
- `terraform destroy` leaves `rg-az-infra-tfstate` in place; it isn't managed by Terraform.

## Design decisions

- **Folder per environment.** I gave dev and prod their own root folders and state files, sharing the same modules. Each environment can be planned and destroyed without touching the other. The cost is that `main.tf` and the other root files are duplicated in both folders.
- **State storage outside Terraform.** I created the state storage with a bootstrap script instead of Terraform. Terraform can't store its state in a storage account it's about to create, and `terraform destroy` can never delete it by accident. Blob versioning keeps earlier versions of every state file.
- **Two resource groups, split by team.** Network resources and compute resources live in separate resource groups, so netops and appops can each get a role on only their own group.
- **One entry point.** I made the jump VM the only VM with a public IP and limited SSH to one `/32` address, passed in at run time instead of written in the code. The `deny-vnet-inbound` rule then makes every internal path explicit.
- **Core tags can't be overridden.** Each environment adds its own tags in `terraform.tfvars`, but I merge the core tags last, so `environment` and `managed_by` are always correct. The required-tag policies depend on those two.
- **Non-overlapping address ranges.** Dev uses `10.10.0.0/16` and prod `10.20.0.0/16`, so the two networks could be peered later without readdressing.
- **Separate SSH key per environment.** A leaked dev key gives no access to prod.
- **Prod is plan-only.** The dev VMs use the full 6-vCPU quota, and the governance module creates subscription-wide policies and groups. Applying prod in the same subscription would need more quota and would duplicate subscription-level governance.
- **Auto-shutdown removed.** I tried a shutdown schedule for the VMs, but the resource type (`Microsoft.DevTestLab/schedules`) isn't offered in `indiasouthcentral`, and my own location policy blocks other regions. Since then, I check a resource type's region availability before using it, not just its provider registration.
- **No budget resource.** Azure for Students has a hard credit limit, and the subscription is disabled when credit runs out, and Education Hub already shows the remaining credit, so a budget alert would add little. Instead, `dev` is destroyed after every session.

## What I'd do differently in production

- **Azure Bastion instead of a public jump VM.** No VM would need a public IP or an open SSH port.
- **Budgets per subscription.** A Cost Management budget alerting the team named in the `owner` tag, with the `cost_center` tag driving cost allocation.
- **Auto-shutdown that works in the region.** A scheduled Azure Automation job, or a region that supports shutdown schedules.
- **Pinned VM image.** A fixed image version instead of `latest`, so every deployment builds the same machine.

## Cost and cleanup

Dev is destroyed at the end of every working session, so the VMs, disks and public IP only cost money while in use. Only the state storage (`rg-az-infra-tfstate`) and `NetworkWatcherRG` remain between sessions.
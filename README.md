# terraform-proxmox-talos-linux-cluster

[![CI](https://github.com/emerson-silva/terraform-proxmox-talos-linux-cluster/actions/workflows/ci.yml/badge.svg)](https://github.com/emerson-silva/terraform-proxmox-talos-linux-cluster/actions/workflows/ci.yml)
[![Terraform Registry](https://img.shields.io/badge/Terraform-Registry-7B42BC?logo=terraform)](https://registry.terraform.io/modules/emerson-silva/talos-linux-cluster/proxmox/latest)
[![OpenTofu Registry](https://img.shields.io/badge/OpenTofu-Registry-FFDA18?logo=opentofu&logoColor=black)](https://search.opentofu.org/module/emerson-silva/talos-linux-cluster/proxmox/latest)

Terraform / OpenTofu module to provision a production-ready [Talos Linux](https://www.talos.dev/) Kubernetes cluster on Proxmox VE using the [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) and [siderolabs/talos](https://registry.terraform.io/providers/siderolabs/talos/latest) providers.

Features:

- Automatic Talos ISO download from [factory.talos.dev](https://factory.talos.dev) directly into Proxmox storage — no manual image preparation
- Static IP per node, configured entirely via `tfvars`
- Custom node names and quantity for controlplane and workers
- Separate CPU, memory, and disk settings per role
- Optional HA controlplane with Talos native VIP — enabled automatically when `controlplane_vip` is set
- `kubeconfig` and `talosconfig` exported as Terraform outputs after cluster bootstrap

## Architecture

Three composable internal modules:

```
modules/
  talos-image/    # downloads the Talos nocloud ISO into Proxmox
  talos-cluster/  # generates machineconfigs (PKI, network, kube-vip patch)
  vm-talos/       # creates each VM and uploads its machineconfig as a snippet
examples/
  cluster/        # wires all modules together, runs bootstrap, outputs credentials
```

## Prerequisites

### 1. Proxmox API token

```bash
pveum user add terraform@pve
pveum aclmod / -user terraform@pve -role Administrator
pveum user token add terraform@pve terraform-token --privsep=0
```

### 2. Enable snippets on the `local` datastore

In the Proxmox UI go to **Datacenter → Storage → local → Edit** and enable the **Snippets** content type. This is required for the machineconfig upload.

### 3. Talos schematic ID

Generate a schematic at [factory.talos.dev](https://factory.talos.dev). For a vanilla image with no extra extensions:

```json
{ "customization": { "systemExtensions": { "officialExtensions": [] } } }
```

Copy the resulting 64-character schematic ID — it goes into `talos_schematic_id`.

## Usage

```hcl
module "talos_cluster" {
  source  = "emerson-silva/talos-linux-cluster/proxmox"
  version = "~> 1.0"

  target_node          = "pve"
  talos_version        = "1.13.3"
  talos_schematic_id   = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4b"
  kubernetes_version   = ""          # leave empty to use Talos default (recommended)
  network_gateway_ipv4 = "192.168.1.1"
  cluster_name         = "talos-lab"
  controlplane_vip     = "192.168.1.200"

  controlplane_nodes = {
    "talos-cp-1" = { vm_id = 201, ip = "192.168.1.201" }
    "talos-cp-2" = { vm_id = 202, ip = "192.168.1.202" }
    "talos-cp-3" = { vm_id = 203, ip = "192.168.1.203" }
  }

  worker_nodes = {
    "talos-worker-1" = { vm_id = 211, ip = "192.168.1.211" }
    "talos-worker-2" = { vm_id = 212, ip = "192.168.1.212" }
  }
}

output "kubeconfig" {
  value     = module.talos_cluster.kubeconfig
  sensitive = true
}
```

> The provider must be configured in the root module — see [Provider configuration](#provider-configuration).

### Run from the example

```bash
git clone https://github.com/emerson-silva/terraform-proxmox-talos-linux-cluster
cd terraform-proxmox-talos-linux-cluster/examples/cluster

cp ../../tfvars/terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars with your values

tofu init
tofu apply
```

After apply completes, export the credentials and verify the cluster:

```bash
# Export kubeconfig
tofu output -raw kubeconfig > ~/.kube/talos-lab.yaml
export KUBECONFIG=~/.kube/talos-lab.yaml

# Wait for nodes to become Ready (CNI initialisation takes ~1-2 min)
kubectl get nodes -w

# Export talosconfig
tofu output -raw talosconfig > ~/.talos/config

# Full cluster health check
talosctl --nodes <controlplane-ip> health
```

Expected output once the cluster is healthy:

```
NAME              STATUS   ROLES           AGE     VERSION
talos-<id>        Ready    control-plane   2m      v1.36.0
talos-<id>        Ready    <none>          2m      v1.36.0
```

### Accessing the cluster later

```bash
export KUBECONFIG=~/.kube/talos-lab.yaml
kubectl get pods -A
talosctl --nodes <controlplane-ip> dashboard
```

## Example `terraform.tfvars`

```hcl
proxmox_endpoint         = "https://192.168.1.100:8006"
proxmox_api_token_id     = "root@pam!terraform-token"
proxmox_api_token_secret = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
proxmox_ssh_username     = "root"
proxmox_ssh_password     = "secret"

target_node = "pve"

talos_version      = "1.13.3"
talos_schematic_id = "376567988ad370138ad8b2698212367b8edcb69b5fd68c80be1f2ec7d603b4b"

network_gateway_ipv4 = "192.168.1.1"
network_prefix       = 24

cluster_name     = "talos-lab"
controlplane_vip = "192.168.1.200"   # omit or set to "" for single-CP clusters

# Keys are VM hostnames; vm_id must be unique in the Proxmox cluster.
controlplane_nodes = {
  "talos-cp-1" = { vm_id = 201, ip = "192.168.1.201" }
  "talos-cp-2" = { vm_id = 202, ip = "192.168.1.202" }
  "talos-cp-3" = { vm_id = 203, ip = "192.168.1.203" }
}

controlplane_cores     = 2
controlplane_memory_mb = 2048
controlplane_disk_gb   = 20

worker_nodes = {
  "talos-worker-1" = { vm_id = 211, ip = "192.168.1.211" }
  "talos-worker-2" = { vm_id = 212, ip = "192.168.1.212" }
  "talos-worker-3" = { vm_id = 213, ip = "192.168.1.213" }
}

worker_cores     = 4
worker_memory_mb = 4096
worker_disk_gb   = 40
```

### Single-node cluster (no workers, no HA)

```hcl
controlplane_vip = ""

controlplane_nodes = {
  "talos-cp-1" = { vm_id = 201, ip = "192.168.1.201" }
}

worker_nodes = {}
```

### HA controlplane without workers

```hcl
controlplane_vip = "192.168.1.200"

controlplane_nodes = {
  "talos-cp-1" = { vm_id = 201, ip = "192.168.1.201" }
  "talos-cp-2" = { vm_id = 202, ip = "192.168.1.202" }
  "talos-cp-3" = { vm_id = 203, ip = "192.168.1.203" }
}

worker_nodes = {}
```

## Provider configuration

Configure the providers in the module that calls this one:

```hcl
provider "proxmox" {
  endpoint  = "https://pve.example.com:8006"
  api_token = "root@pam!my-token=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  insecure  = true

  ssh {
    agent    = false
    username = "root"
    password = "secret"
  }
}
```

## Requirements

Compatible with both **Terraform** and **OpenTofu**.

| Name | Version |
|------|---------|
| [Terraform](https://www.terraform.io/downloads) | >= 1.6.0 |
| [OpenTofu](https://opentofu.org/docs/intro/install/) | >= 1.6.0 |
| [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) | >= 0.60.0 |
| [siderolabs/talos](https://registry.terraform.io/providers/siderolabs/talos/latest) | >= 0.7.0 |

## Inputs

### Proxmox provider

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `proxmox_endpoint` | Proxmox API URL (e.g. `https://pve:8006`) | `string` | — | yes |
| `proxmox_api_token_id` | API token ID (`user@realm!token`) | `string` | — | yes |
| `proxmox_api_token_secret` | API token secret | `string` | — | yes |
| `proxmox_insecure` | Skip TLS verification | `bool` | `true` | no |
| `proxmox_ssh_username` | SSH username for file uploads | `string` | `"root"` | no |
| `proxmox_ssh_password` | SSH password | `string` | — | yes |

### Proxmox placement

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `target_node` | Proxmox node name | `string` | `"pve"` | no |
| `disk_storage` | Datastore for VM boot disks | `string` | `"local-lvm"` | no |
| `cloud_init_datastore` | Datastore for cloud-init drives | `string` | `"local-lvm"` | no |
| `snippets_datastore` | Datastore for machineconfig snippets | `string` | `"local"` | no |
| `iso_datastore` | Datastore where the Talos ISO is downloaded | `string` | `"local"` | no |

### Talos image

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `talos_version` | Talos version without `v` prefix (e.g. `1.13.3`) | `string` | — | yes |
| `talos_schematic_id` | 64-char schematic ID from factory.talos.dev | `string` | — | yes |
| `kubernetes_version` | Kubernetes version to deploy (e.g. `1.32.3`). Empty = Talos default | `string` | `""` | no |

### Network

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `network_gateway_ipv4` | IPv4 default gateway for all nodes | `string` | — | yes |
| `network_prefix` | Subnet prefix length (e.g. `24`) | `number` | `24` | no |
| `network_bridge` | Proxmox bridge interface | `string` | `"vmbr0"` | no |
| `network_vlan_id` | VLAN tag (0 = no VLAN) | `number` | `0` | no |
| `dns_servers` | DNS servers for all nodes | `list(string)` | `["8.8.8.8","1.1.1.1"]` | no |

### Cluster

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `cluster_name` | Cluster name (used in kubeconfig and machineconfig) | `string` | — | yes |
| `controlplane_vip` | Virtual IP for kube-vip HA. `""` disables kube-vip | `string` | `""` | no |

### Controlplane nodes

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `controlplane_nodes` | Map of `hostname → { vm_id, ip }` | `map(object)` | — | yes |
| `controlplane_cores` | vCPU count | `number` | `2` | no |
| `controlplane_memory_mb` | RAM in MiB | `number` | `2048` | no |
| `controlplane_disk_gb` | Boot disk size in GiB | `number` | `20` | no |

### Worker nodes

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `worker_nodes` | Map of `hostname → { vm_id, ip }`. Empty = no workers | `map(object)` | `{}` | no |
| `worker_cores` | vCPU count | `number` | `4` | no |
| `worker_memory_mb` | RAM in MiB | `number` | `4096` | no |
| `worker_disk_gb` | Boot disk size in GiB | `number` | `40` | no |

## Outputs

| Name | Description | Sensitive |
|------|-------------|-----------|
| `cluster_endpoint` | Kubernetes API endpoint | no |
| `kubeconfig` | Raw kubeconfig YAML | yes |
| `talosconfig` | Raw talosconfig YAML | yes |
| `controlplane_ips` | Map of controlplane hostname → IP | no |
| `worker_ips` | Map of worker hostname → IP | no |
| `talos_iso_file_id` | Proxmox file reference for the downloaded ISO | no |

## Version compatibility

Each Talos release ships a default Kubernetes version and a supported range. The table below shows the tested combinations:

| Talos | Default K8s | Supported K8s range |
|-------|-------------|---------------------|
| 1.13.x | 1.32.x | 1.30 – 1.33 |
| 1.12.x | 1.31.x | 1.29 – 1.32 |
| 1.11.x | 1.30.x | 1.28 – 1.31 |

> For the authoritative list see the [Talos support matrix](https://www.talos.dev/latest/introduction/support-matrix/).

By default the module lets Talos pick its bundled Kubernetes version. To pin a specific version set `kubernetes_version` in your `terraform.tfvars`:

```hcl
talos_version      = "1.13.3"
kubernetes_version = "1.32.3"   # optional — leave empty to use Talos default
```

If you omit `kubernetes_version` (or set it to `""`), Talos uses whatever version ships with the `talos_version` you specified — this is the recommended default for new clusters.

## How it works

1. **ISO download** — `modules/talos-image` pulls the nocloud ISO directly from `factory.talos.dev` into Proxmox using `proxmox_download_file`. The file name embeds the version and a short schematic prefix to avoid conflicts. Subsequent `apply` runs skip the download (`overwrite = false`).

2. **Machineconfig generation** — `modules/talos-cluster` creates a single `talos_machine_secrets` resource (the cluster PKI) and generates one machineconfig per node. When `controlplane_vip` is set, the native Talos VIP is configured on the controlplane network interface — no external components required.

3. **VM creation** — `modules/vm-talos` uploads each machineconfig as a Proxmox snippet and creates the VM. On first boot, Talos reads the machineconfig via the nocloud cloud-init drive, installs itself to the boot disk, and reboots. The ISO CDROM and cloud-init drive are ignored on subsequent boots (`lifecycle.ignore_changes`).

4. **Bootstrap** — after all VMs are up, `talos_machine_bootstrap` triggers etcd initialization on the first controlplane. Once etcd elects a leader, the Talos VIP is activated on that node's interface. The kubeconfig and talosconfig are then retrieved and exposed as outputs.

## Virtual IP (HA controlplane)

This module uses **Talos native VIP** — a built-in ARP-based virtual IP managed directly by Talos using etcd leader election. It starts before the Kubernetes API server and has no circular dependency.

- Set `controlplane_vip` to an **unused IP** on the same subnet as the controlplane nodes.
- Recommended for clusters with 3+ controlplane nodes (requires an odd number for etcd quorum).
- When `controlplane_vip` is set, the Kubernetes API endpoint and talosconfig endpoints all point to the VIP. When it is empty, the first controlplane IP is used directly.

## License

MIT

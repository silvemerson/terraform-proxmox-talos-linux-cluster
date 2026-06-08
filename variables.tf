# ---------------------------------------------------------------------------
# Proxmox placement
# ---------------------------------------------------------------------------
variable "target_node" {
  description = "Proxmox node name where VMs will be created."
  type        = string
}

variable "disk_storage" {
  description = "Proxmox datastore for VM boot disks."
  type        = string
  default     = "local-lvm"
}

variable "cloud_init_datastore" {
  description = "Proxmox datastore for cloud-init drives."
  type        = string
  default     = "local-lvm"
}

variable "snippets_datastore" {
  description = "Proxmox datastore for machineconfig snippets (must have 'Snippets' content type enabled — usually 'local')."
  type        = string
  default     = "local"
}

variable "iso_datastore" {
  description = "Proxmox datastore where the Talos ISO will be downloaded (must have 'ISO image' content type — usually 'local')."
  type        = string
  default     = "local"
}

# ---------------------------------------------------------------------------
# Talos image
# ---------------------------------------------------------------------------
variable "talos_version" {
  description = "Talos version without 'v' prefix (e.g. 1.9.5)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "talos_version must be in X.Y.Z format (no 'v' prefix)."
  }
}

variable "talos_schematic_id" {
  description = "Talos factory schematic ID, generated at factory.talos.dev."
  type        = string

  validation {
    condition     = length(var.talos_schematic_id) == 64
    error_message = "talos_schematic_id must be a 64-character hex string."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy (e.g. 1.32.3). Leave empty to use the default bundled with the chosen Talos version. See README for the Talos ↔ Kubernetes compatibility table."
  type        = string
  default     = ""

  validation {
    condition     = var.kubernetes_version == "" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in X.Y.Z format or empty string."
  }
}

# ---------------------------------------------------------------------------
# Network (shared by all nodes)
# ---------------------------------------------------------------------------
variable "network_bridge" {
  description = "Proxmox bridge interface for all cluster NICs (e.g. vmbr0)."
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN tag for all cluster NICs. Use 0 for no VLAN."
  type        = number
  default     = 0
}

variable "network_prefix" {
  description = "Subnet prefix length shared by all nodes (e.g. 24 for /24)."
  type        = number
  default     = 24
}

variable "network_gateway_ipv4" {
  description = "IPv4 default gateway for all cluster nodes."
  type        = string
}

variable "dns_servers" {
  description = "DNS servers configured in each node's machineconfig."
  type        = list(string)
  default     = ["8.8.8.8", "1.1.1.1"]

  validation {
    condition     = length(var.dns_servers) > 0
    error_message = "At least one DNS server is required."
  }
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
variable "cluster_name" {
  description = "Talos / Kubernetes cluster name (used in kubeconfig and machineconfig)."
  type        = string

  validation {
    condition     = length(trim(var.cluster_name, " ")) > 0
    error_message = "cluster_name cannot be empty."
  }
}

variable "controlplane_vip" {
  description = "Virtual IP advertised by kube-vip on controlplane nodes. Leave empty to disable kube-vip and use the first controlplane IP directly."
  type        = string
  default     = ""
}

# ---------------------------------------------------------------------------
# Controlplane nodes
# ---------------------------------------------------------------------------
variable "controlplane_nodes" {
  description = "Map of controlplane node hostname → { vm_id, ip }. The key becomes the VM name and Talos hostname."
  type = map(object({
    vm_id = number
    ip    = string
  }))

  validation {
    condition     = length(var.controlplane_nodes) >= 1
    error_message = "At least one controlplane node is required."
  }
}

variable "controlplane_cores" {
  description = "vCPU count for controlplane nodes."
  type        = number
  default     = 2

  validation {
    condition     = var.controlplane_cores >= 1
    error_message = "controlplane_cores must be at least 1."
  }
}

variable "controlplane_memory_mb" {
  description = "RAM in MiB for controlplane nodes."
  type        = number
  default     = 2048

  validation {
    condition     = var.controlplane_memory_mb >= 2048
    error_message = "controlplane_memory_mb must be at least 2048 MiB."
  }
}

variable "controlplane_disk_gb" {
  description = "Boot disk size in GiB for controlplane nodes."
  type        = number
  default     = 20

  validation {
    condition     = var.controlplane_disk_gb >= 10
    error_message = "controlplane_disk_gb must be at least 10 GiB."
  }
}

# ---------------------------------------------------------------------------
# Worker nodes
# ---------------------------------------------------------------------------
variable "worker_nodes" {
  description = "Map of worker node hostname → { vm_id, ip }. Empty map for control-plane-only clusters."
  type = map(object({
    vm_id = number
    ip    = string
  }))
  default = {}
}

variable "worker_cores" {
  description = "vCPU count for worker nodes."
  type        = number
  default     = 4

  validation {
    condition     = var.worker_cores >= 1
    error_message = "worker_cores must be at least 1."
  }
}

variable "worker_memory_mb" {
  description = "RAM in MiB for worker nodes."
  type        = number
  default     = 4096

  validation {
    condition     = var.worker_memory_mb >= 1024
    error_message = "worker_memory_mb must be at least 1024 MiB."
  }
}

variable "worker_disk_gb" {
  description = "Boot disk size in GiB for worker nodes."
  type        = number
  default     = 40

  validation {
    condition     = var.worker_disk_gb >= 10
    error_message = "worker_disk_gb must be at least 10 GiB."
  }
}

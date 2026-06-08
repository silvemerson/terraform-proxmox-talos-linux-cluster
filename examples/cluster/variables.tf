# ---------------------------------------------------------------------------
# Proxmox provider
# ---------------------------------------------------------------------------
variable "proxmox_endpoint" {
  description = "Proxmox API endpoint (e.g. https://192.168.1.100:8006)."
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API token ID in user@realm!token form."
  type        = string
  sensitive   = true
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API token secret value."
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS certificate verification."
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username on the Proxmox host."
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "SSH password on the Proxmox host."
  type        = string
  sensitive   = true
}

# ---------------------------------------------------------------------------
# Proxmox placement
# ---------------------------------------------------------------------------
variable "target_node" {
  type    = string
  default = "pve"
}

variable "disk_storage" {
  type    = string
  default = "local-lvm"
}

variable "cloud_init_datastore" {
  type    = string
  default = "local-lvm"
}

variable "snippets_datastore" {
  type    = string
  default = "local"
}

variable "iso_datastore" {
  type    = string
  default = "local"
}

# ---------------------------------------------------------------------------
# Talos image
# ---------------------------------------------------------------------------
variable "talos_version" {
  type = string
}

variable "talos_schematic_id" {
  type = string
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_vlan_id" {
  type    = number
  default = 0
}

variable "network_prefix" {
  type    = number
  default = 24
}

variable "network_gateway_ipv4" {
  type = string
}

variable "dns_servers" {
  type    = list(string)
  default = ["8.8.8.8", "1.1.1.1"]
}

# ---------------------------------------------------------------------------
# Cluster
# ---------------------------------------------------------------------------
variable "cluster_name" {
  type = string
}

variable "controlplane_vip" {
  type    = string
  default = ""
}

# ---------------------------------------------------------------------------
# Controlplane nodes
# ---------------------------------------------------------------------------
variable "controlplane_nodes" {
  type = map(object({
    vm_id = number
    ip    = string
  }))
}

variable "controlplane_cores" {
  type    = number
  default = 2
}

variable "controlplane_memory_mb" {
  type    = number
  default = 2048
}

variable "controlplane_disk_gb" {
  type    = number
  default = 20
}

# ---------------------------------------------------------------------------
# Worker nodes
# ---------------------------------------------------------------------------
variable "worker_nodes" {
  type = map(object({
    vm_id = number
    ip    = string
  }))
  default = {}
}

variable "worker_cores" {
  type    = number
  default = 4
}

variable "worker_memory_mb" {
  type    = number
  default = 4096
}

variable "worker_disk_gb" {
  type    = number
  default = 40
}

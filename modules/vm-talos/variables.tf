# ---------------------------------------------------------------------------
# Proxmox placement
# ---------------------------------------------------------------------------
variable "target_node" {
  description = "Proxmox node name where the VM will run."
  type        = string
}

variable "vm_id" {
  description = "Unique VM ID in the Proxmox cluster (100–999999999)."
  type        = number

  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999999
    error_message = "vm_id must be between 100 and 999999999."
  }
}

variable "vm_name" {
  description = "VM hostname shown in Proxmox."
  type        = string

  validation {
    condition     = length(trim(var.vm_name, " ")) > 0
    error_message = "vm_name cannot be empty."
  }
}

variable "description" {
  description = "Free-text VM description shown in the Proxmox UI."
  type        = string
  default     = "Managed by Terraform - Talos node"
}

variable "tags" {
  description = "Tags applied to the VM in Proxmox."
  type        = list(string)
  default     = ["terraform", "talos"]
}

# ---------------------------------------------------------------------------
# Talos ISO
# ---------------------------------------------------------------------------
variable "talos_iso_id" {
  description = "Proxmox file reference for the Talos nocloud ISO (e.g. local:iso/talos-1.9.5-nocloud-amd64.iso)."
  type        = string
}

# ---------------------------------------------------------------------------
# Compute
# ---------------------------------------------------------------------------
variable "vm_cores" {
  description = "Number of vCPU cores."
  type        = number
  default     = 2

  validation {
    condition     = var.vm_cores >= 1 && var.vm_cores <= 128
    error_message = "vm_cores must be between 1 and 128."
  }
}

variable "vm_memory_mb" {
  description = "RAM allocated to the VM in MiB."
  type        = number
  default     = 2048

  validation {
    condition     = var.vm_memory_mb >= 512
    error_message = "vm_memory_mb must be at least 512 MiB."
  }
}

# ---------------------------------------------------------------------------
# Storage
# ---------------------------------------------------------------------------
variable "disk_size_gb" {
  description = "Boot disk size in GiB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb >= 10
    error_message = "disk_size_gb must be at least 10 GiB."
  }
}

variable "disk_storage" {
  description = "Proxmox datastore for the VM boot disk."
  type        = string
  default     = "local-lvm"
}

variable "cloud_init_datastore" {
  description = "Proxmox datastore for the cloud-init drive."
  type        = string
  default     = "local-lvm"
}

variable "snippets_datastore" {
  description = "Proxmox datastore for snippet files (must have 'snippets' content type enabled — usually 'local')."
  type        = string
  default     = "local"
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
variable "network_bridge" {
  description = "Proxmox bridge interface for the primary NIC (e.g. vmbr0)."
  type        = string
  default     = "vmbr0"
}

variable "network_vlan_id" {
  description = "VLAN tag for the primary NIC. Use 0 for no VLAN."
  type        = number
  default     = 0
}

# ---------------------------------------------------------------------------
# Talos machineconfig
# ---------------------------------------------------------------------------
variable "machine_config" {
  description = "Talos machineconfig YAML passed as nocloud user-data."
  type        = string
  sensitive   = true
}

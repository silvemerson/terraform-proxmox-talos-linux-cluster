variable "node_name" {
  description = "Proxmox node where the ISO will be downloaded."
  type        = string
}

variable "datastore_id" {
  description = "Proxmox datastore for the ISO (must have 'iso' content type — usually 'local')."
  type        = string
  default     = "local"
}

variable "talos_version" {
  description = "Talos version without 'v' prefix (e.g. 1.9.5)."
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.talos_version))
    error_message = "talos_version must be in X.Y.Z format (no 'v' prefix)."
  }
}

variable "schematic_id" {
  description = "Talos factory schematic ID, generated at factory.talos.dev."
  type        = string

  validation {
    condition     = length(var.schematic_id) == 64
    error_message = "schematic_id must be a 64-character hex string."
  }
}

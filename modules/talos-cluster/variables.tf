# ---------------------------------------------------------------------------
# Cluster identity
# ---------------------------------------------------------------------------
variable "cluster_name" {
  description = "Talos / Kubernetes cluster name."
  type        = string

  validation {
    condition     = length(trim(var.cluster_name, " ")) > 0
    error_message = "cluster_name cannot be empty."
  }
}

variable "cluster_endpoint" {
  description = "Kubernetes API endpoint used in kubeconfig and machineconfig (e.g. https://192.168.1.200:6443)."
  type        = string
}

# ---------------------------------------------------------------------------
# Talos version
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
  description = "Talos factory schematic ID (generated at factory.talos.dev)."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version to deploy (e.g. 1.32.3). Leave empty to use the default bundled with the chosen Talos version."
  type        = string
  default     = ""

  validation {
    condition     = var.kubernetes_version == "" || can(regex("^[0-9]+\\.[0-9]+\\.[0-9]+$", var.kubernetes_version))
    error_message = "kubernetes_version must be in X.Y.Z format or empty string."
  }
}

# ---------------------------------------------------------------------------
# Network
# ---------------------------------------------------------------------------
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
# Node definitions
# ---------------------------------------------------------------------------
variable "controlplane_nodes" {
  description = "Map of controlplane node name → { ip, prefix, gateway }."
  type = map(object({
    ip      = string
    prefix  = number
    gateway = string
  }))

  validation {
    condition     = length(var.controlplane_nodes) >= 1
    error_message = "At least one controlplane node is required."
  }
}

variable "worker_nodes" {
  description = "Map of worker node name → { ip, prefix, gateway }. Empty map for control-plane-only clusters."
  type = map(object({
    ip      = string
    prefix  = number
    gateway = string
  }))
  default = {}
}

# ---------------------------------------------------------------------------
# HA / kube-vip
# ---------------------------------------------------------------------------
variable "controlplane_vip" {
  description = "Virtual IP advertised by kube-vip on controlplane nodes. Empty string disables kube-vip."
  type        = string
  default     = ""
}


terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.7.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_api_token_id}=${var.proxmox_api_token_secret}"
  insecure  = var.proxmox_insecure

  ssh {
    agent    = false
    username = var.proxmox_ssh_username
    password = var.proxmox_ssh_password
  }
}

module "talos_cluster" {
  source = "../.."

  target_node          = var.target_node
  disk_storage         = var.disk_storage
  cloud_init_datastore = var.cloud_init_datastore
  snippets_datastore   = var.snippets_datastore
  iso_datastore        = var.iso_datastore

  talos_version      = var.talos_version
  talos_schematic_id = var.talos_schematic_id

  network_bridge       = var.network_bridge
  network_vlan_id      = var.network_vlan_id
  network_prefix       = var.network_prefix
  network_gateway_ipv4 = var.network_gateway_ipv4
  dns_servers          = var.dns_servers

  cluster_name     = var.cluster_name
  controlplane_vip = var.controlplane_vip

  controlplane_nodes     = var.controlplane_nodes
  controlplane_cores     = var.controlplane_cores
  controlplane_memory_mb = var.controlplane_memory_mb
  controlplane_disk_gb   = var.controlplane_disk_gb

  worker_nodes     = var.worker_nodes
  worker_cores     = var.worker_cores
  worker_memory_mb = var.worker_memory_mb
  worker_disk_gb   = var.worker_disk_gb
}

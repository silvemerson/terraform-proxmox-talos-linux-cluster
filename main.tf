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

# ---------------------------------------------------------------------------
# Locals — enrich node maps with shared network values
# ---------------------------------------------------------------------------
locals {
  controlplane_full = {
    for name, node in var.controlplane_nodes : name => {
      vm_id   = node.vm_id
      ip      = node.ip
      prefix  = var.network_prefix
      gateway = var.network_gateway_ipv4
    }
  }

  worker_full = {
    for name, node in var.worker_nodes : name => {
      vm_id   = node.vm_id
      ip      = node.ip
      prefix  = var.network_prefix
      gateway = var.network_gateway_ipv4
    }
  }

  first_cp_ip      = values(var.controlplane_nodes)[0].ip
  cluster_endpoint = "https://${coalesce(var.controlplane_vip, local.first_cp_ip)}:6443"
}

# ---------------------------------------------------------------------------
# Download Talos ISO to Proxmox automatically
# ---------------------------------------------------------------------------
module "talos_image" {
  source = "./modules/talos-image"

  node_name     = var.target_node
  datastore_id  = var.iso_datastore
  talos_version = var.talos_version
  schematic_id  = var.talos_schematic_id
}

# ---------------------------------------------------------------------------
# Generate machineconfigs (controlplane + worker)
# ---------------------------------------------------------------------------
module "talos_cluster" {
  source = "./modules/talos-cluster"

  cluster_name       = var.cluster_name
  cluster_endpoint   = local.cluster_endpoint
  talos_version      = var.talos_version
  talos_schematic_id = var.talos_schematic_id
  kubernetes_version = var.kubernetes_version
  dns_servers        = var.dns_servers
  controlplane_vip   = var.controlplane_vip

  controlplane_nodes = {
    for name, node in local.controlplane_full : name => {
      ip      = node.ip
      prefix  = node.prefix
      gateway = node.gateway
    }
  }

  worker_nodes = {
    for name, node in local.worker_full : name => {
      ip      = node.ip
      prefix  = node.prefix
      gateway = node.gateway
    }
  }
}

# ---------------------------------------------------------------------------
# Controlplane VMs
# ---------------------------------------------------------------------------
module "controlplane" {
  source   = "./modules/vm-talos"
  for_each = local.controlplane_full

  target_node  = var.target_node
  vm_id        = each.value.vm_id
  vm_name      = each.key
  description  = "Talos controlplane – ${each.key} – managed by Terraform"
  talos_iso_id = module.talos_image.iso_file_id

  vm_cores     = var.controlplane_cores
  vm_memory_mb = var.controlplane_memory_mb
  disk_size_gb = var.controlplane_disk_gb
  disk_storage = var.disk_storage

  network_bridge       = var.network_bridge
  network_vlan_id      = var.network_vlan_id
  snippets_datastore   = var.snippets_datastore
  cloud_init_datastore = var.cloud_init_datastore

  machine_config = module.talos_cluster.controlplane_configs[each.key]
  tags           = ["terraform", "talos", "controlplane"]
}

# ---------------------------------------------------------------------------
# Worker VMs
# ---------------------------------------------------------------------------
module "worker" {
  source   = "./modules/vm-talos"
  for_each = local.worker_full

  target_node  = var.target_node
  vm_id        = each.value.vm_id
  vm_name      = each.key
  description  = "Talos worker – ${each.key} – managed by Terraform"
  talos_iso_id = module.talos_image.iso_file_id

  vm_cores     = var.worker_cores
  vm_memory_mb = var.worker_memory_mb
  disk_size_gb = var.worker_disk_gb
  disk_storage = var.disk_storage

  network_bridge       = var.network_bridge
  network_vlan_id      = var.network_vlan_id
  snippets_datastore   = var.snippets_datastore
  cloud_init_datastore = var.cloud_init_datastore

  machine_config = module.talos_cluster.worker_configs[each.key]
  tags           = ["terraform", "talos", "worker"]
}

# ---------------------------------------------------------------------------
# Bootstrap — triggers etcd init on the first controlplane after VMs are up
# ---------------------------------------------------------------------------
resource "talos_machine_bootstrap" "this" {
  depends_on = [module.controlplane, module.worker]

  client_configuration = module.talos_cluster.client_configuration
  node                 = local.first_cp_ip
  endpoint             = local.first_cp_ip
}

# ---------------------------------------------------------------------------
# Kubeconfig
# ---------------------------------------------------------------------------
resource "talos_cluster_kubeconfig" "this" {
  depends_on = [talos_machine_bootstrap.this]

  client_configuration = module.talos_cluster.client_configuration
  node                 = local.first_cp_ip
  endpoint             = local.first_cp_ip
}

# ---------------------------------------------------------------------------
# Talosconfig
# ---------------------------------------------------------------------------
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster_name
  client_configuration = module.talos_cluster.client_configuration
  endpoints            = [for _, n in var.controlplane_nodes : n.ip]
  nodes                = [for _, n in var.controlplane_nodes : n.ip]
}

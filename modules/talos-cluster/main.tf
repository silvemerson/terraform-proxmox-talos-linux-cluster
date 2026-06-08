terraform {
  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = ">= 0.7.0"
    }
  }
}

locals {
  install_image = "factory.talos.dev/nocloud-installer/${var.talos_schematic_id}:v${var.talos_version}"
}

# Generates cluster PKI + secrets and persists them in state.
# WARNING: destroying this resource forces a full cluster rebuild.
resource "talos_machine_secrets" "this" {
  talos_version = "v${var.talos_version}"
}

# ---------------------------------------------------------------------------
# Controlplane machineconfigs
# ---------------------------------------------------------------------------
data "talos_machine_configuration" "controlplane" {
  for_each = var.controlplane_nodes

  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = local.install_image
        }
        network = {
          nameservers = var.dns_servers
          interfaces = [merge(
            {
              interface = "eth0"
              addresses = ["${each.value.ip}/${each.value.prefix}"]
              routes = [{
                network = "0.0.0.0/0"
                gateway = each.value.gateway
              }]
            },
            # Talos native VIP — enabled when controlplane_vip is set.
            # Talos manages the VIP via ARP using etcd leader election,
            # with no dependency on the Kubernetes API.
            var.controlplane_vip != "" ? { vip = { ip = var.controlplane_vip } } : {}
          )]
        }
      }
    }),
  ]
}

# ---------------------------------------------------------------------------
# Worker machineconfigs
# ---------------------------------------------------------------------------
data "talos_machine_configuration" "worker" {
  for_each = var.worker_nodes

  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = var.cluster_endpoint
  machine_secrets    = talos_machine_secrets.this.machine_secrets
  talos_version      = "v${var.talos_version}"
  kubernetes_version = var.kubernetes_version != "" ? var.kubernetes_version : null

  config_patches = [
    yamlencode({
      machine = {
        install = {
          image = local.install_image
        }
        network = {
          nameservers = var.dns_servers
          interfaces = [{
            interface = "eth0"
            addresses = ["${each.value.ip}/${each.value.prefix}"]
            routes = [{
              network = "0.0.0.0/0"
              gateway = each.value.gateway
            }]
          }]
        }
      }
    }),
  ]
}

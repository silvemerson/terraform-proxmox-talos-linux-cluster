terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.60.0"
    }
  }
}

locals {
  # short prefix from schematic to avoid collisions between different schematics
  schematic_prefix = substr(var.schematic_id, 0, 8)
  iso_file_name    = "talos-${var.talos_version}-${local.schematic_prefix}-nocloud-amd64.iso"
  download_url     = "https://factory.talos.dev/image/${var.schematic_id}/v${var.talos_version}/nocloud-amd64.iso"
}

resource "proxmox_download_file" "talos_iso" {
  content_type        = "iso"
  datastore_id        = var.datastore_id
  node_name           = var.node_name
  url                 = local.download_url
  file_name           = local.iso_file_name
  overwrite           = false
  overwrite_unmanaged = true
}

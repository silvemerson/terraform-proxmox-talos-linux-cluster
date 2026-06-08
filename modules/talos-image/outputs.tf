output "iso_file_id" {
  description = "Proxmox file reference for the Talos ISO (e.g. local:iso/talos-1.9.5-nocloud-amd64.iso)."
  value       = proxmox_download_file.talos_iso.id
}

output "iso_file_name" {
  description = "File name of the downloaded ISO."
  value       = local.iso_file_name
}

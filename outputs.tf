output "cluster_endpoint" {
  description = "Kubernetes API endpoint."
  value       = local.cluster_endpoint
}

output "kubeconfig" {
  description = "Raw kubeconfig YAML. Save to ~/.kube/config or use the KUBECONFIG env var."
  value       = resource.talos_cluster_kubeconfig.this.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Raw talosconfig YAML. Save to ~/.talos/config."
  value       = data.talos_client_configuration.this.talos_config
  sensitive   = true
}

output "controlplane_ips" {
  description = "Map of controlplane node hostname → IP."
  value       = { for name, node in var.controlplane_nodes : name => node.ip }
}

output "worker_ips" {
  description = "Map of worker node hostname → IP."
  value       = { for name, node in var.worker_nodes : name => node.ip }
}

output "talos_iso_file_id" {
  description = "Proxmox file reference for the downloaded Talos ISO (e.g. local:iso/talos-1.9.5-nocloud-amd64.iso)."
  value       = module.talos_image.iso_file_id
}

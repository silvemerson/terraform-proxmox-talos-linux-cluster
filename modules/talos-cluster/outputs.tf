output "controlplane_configs" {
  description = "Map of controlplane node name → machineconfig YAML."
  value       = { for k, v in data.talos_machine_configuration.controlplane : k => v.machine_configuration }
  sensitive   = true
}

output "worker_configs" {
  description = "Map of worker node name → machineconfig YAML."
  value       = { for k, v in data.talos_machine_configuration.worker : k => v.machine_configuration }
  sensitive   = true
}

output "client_configuration" {
  description = "Talos client configuration used by talosctl, bootstrap, and kubeconfig retrieval."
  value       = talos_machine_secrets.this.client_configuration
  sensitive   = true
}

output "cluster_endpoint" {
  value = module.talos_cluster.cluster_endpoint
}

output "kubeconfig" {
  value     = module.talos_cluster.kubeconfig
  sensitive = true
}

output "talosconfig" {
  value     = module.talos_cluster.talosconfig
  sensitive = true
}

output "controlplane_ips" {
  value = module.talos_cluster.controlplane_ips
}

output "worker_ips" {
  value = module.talos_cluster.worker_ips
}

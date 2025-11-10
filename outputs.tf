output "ssh_command" {
  description = "Command to SSH into the bastion host using IAP."
  value       = "gcloud compute ssh --zone ${google_compute_instance.iap_bastion_host.zone} ${google_compute_instance.iap_bastion_host.name} --project ${data.google_client_config.this.project}"
  sensitive   = false
}

output "sql_proxy_tunnel_commands" {
  description = "A map of commands to start IAP tunnels for each database port."
  value = {
    for port in local.database_ports : "port_${port}" => "gcloud compute start-iap-tunnel ${google_compute_instance.iap_bastion_host.name} ${port} --local-host-port=localhost:${port} --zone ${google_compute_instance.iap_bastion_host.zone} --project ${data.google_client_config.this.project}"
  }
  sensitive = false
}
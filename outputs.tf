output "ssh_command" {
  description = "Command to SSH into the bastion host using IAP."
  value       = "gcloud compute ssh --zone ${google_compute_instance.iap_bastion_host.zone} ${google_compute_instance.iap_bastion_host.name} --project ${data.google_client_config.this.project}"
  sensitive   = false
}

output "sql_proxy_tunnel_command" {
  description = "Command to start an IAP tunnel to the bastion host for the Cloud SQL Proxy."
  value       = "gcloud compute start-iap-tunnel ${google_compute_instance.iap_bastion_host.name} ${var.firewall_allow_database_port} --local-host-port=localhost:${var.firewall_allow_database_port} --zone ${google_compute_instance.iap_bastion_host.zone} --project ${data.google_client_config.this.project}"
  sensitive   = false
}
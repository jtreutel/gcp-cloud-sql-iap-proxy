output "ssh_command" {
  description = "Command to SSH into the bastion host using IAP."
  value       = "gcloud compute ssh --zone ${google_compute_instance.iap_bastion_host.zone} ${google_compute_instance.iap_bastion_host.name} --project ${data.google_client_config.this.project}"
  sensitive   = false
}

output "sql_proxy_tunnel_commands" {
  description = "A map of instance names to the gcloud commands to start their IAP tunnels."
  value = {
    for i, name in var.cloud_sql_instances :
    name => "gcloud compute start-iap-tunnel ${google_compute_instance.iap_bastion_host.name} ${local.proxy_listening_ports[i]} --local-host-port=localhost:${local.proxy_listening_ports[i]} --zone ${google_compute_instance.iap_bastion_host.zone} --project ${data.google_client_config.this.project}"
  }
  sensitive = false
}

output "instance_port_assignments" {
  description = "A map of Cloud SQL instance names to their assigned local proxy ports."
  value = {
    for i, name in var.cloud_sql_instances : name => (var.starting_port + i)
  }
}
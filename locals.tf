locals {
  # Creates a prefix like "prod-" if var.name_prefix is "prod", or "" if var.name_prefix is null or empty.
  prefix = var.name_prefix == null || var.name_prefix == "" ? "" : "${var.name_prefix}-"


  # Build the final, complete argument string for the systemd service
  # It will look like: "--address 0.0.0.0 --iam-authn --port 3306 project:region:db1 --port 3307 project:region:db2"
  sql_proxy_exec_args = "--address 0.0.0.0 --private-ip ${join(" ", [
    for instance in var.cloud_sql_instances : "--port ${instance.port} ${data.google_client_config.this.project}:${data.google_client_config.this.region}:${instance.name}"
  ])}"

  database_ports = distinct([
    for instance in var.cloud_sql_instances : instance.port
  ])
}


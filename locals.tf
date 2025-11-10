locals {
  # Creates a prefix like "prod-" if var.name_prefix is "prod", or "" if var.name_prefix is null or empty.
  prefix = var.name_prefix == null || var.name_prefix == "" ? "" : "${var.name_prefix}-"

  # Create a list of full connection strings, e.g., ["project:region:db1", "project:region:db2"]
  sql_instance_port_map_strings = [
    for instance in var.cloud_sql_instances : "--port ${instance.port} ${data.google_client_config.this.project}:${data.google_client_config.this.region}:${instance.name}"
  ]
  # Join that list into a single, space-separated string for the systemd service
  sql_proxy_exec_args = join(" ", local.sql_instance_port_map_strings)

  database_ports = distinct([
    for instance in var.cloud_sql_instances : instance.port
  ])
}


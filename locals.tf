locals {
  # Creates a prefix like "prod-" if var.name_prefix is "prod", or "" if var.name_prefix is null or empty.
  prefix = var.name_prefix == null || var.name_prefix == "" ? "" : "${var.name_prefix}-"


  # Build the final, complete argument string for the systemd service
  # It will look like: "instance1 instance2 --port 50000 --address 0.0.0.0 --private-ip"
  sql_proxy_exec_args = "${join(" ", [
    for name in var.cloud_sql_instances : "${data.google_client_config.this.project}:${data.google_client_config.this.region}:${name}"
    ]
    )
  } --port ${var.starting_port} --address 0.0.0.0 --private-ip"

  # List of database ports to open in the firewall
  proxy_listening_ports = [
    for i, instance in var.cloud_sql_instances : var.starting_port + i
  ]
}


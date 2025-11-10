locals {
  sql_instance_connection_name = "${data.google_client_config.this.project}:${data.google_client_config.this.region}:${var.sql_instance_name}"
}
###############
# Proxy VM & Networking 
###############

resource "google_compute_instance" "iap_bastion_host" {
  project      = data.google_client_config.this.project
  name         = var.instance_name
  machine_type = var.machine_type
  # This uses the region from your gcloud/provider config to build the zone
  zone = "${data.google_client_config.this.region}-a"

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
  }

  # Download, install, and configure Cloud SQL Proxy
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # Exit immediately if a command fails
    set -e

    # 1. Install prerequisites
    apt-get update
    apt-get install -y curl

    # 2. Download and install the Cloud SQL Proxy
    echo "Downloading Cloud SQL Proxy..."
    curl -o /usr/local/bin/cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/${var.cloud_sql_proxy_version}/cloud-sql-proxy.linux.amd64
    chmod +x /usr/local/bin/cloud-sql-proxy

    # 3. Create a dedicated system user for the proxy
    echo "Creating system user 'cloudsqlproxy'..."
    adduser --system --no-create-home cloudsqlproxy || true

    # 4. Create the systemd service file from the template
    # NOTE: This still assumes you have a "./templates/cloud-sql-proxy.service" file
    # as in your original code.
    echo "Creating systemd service file..."
    cat <<EOF > /etc/systemd/system/cloud-sql-proxy.service
${templatefile("${path.module}/templates/cloud-sql-proxy.service", {
  INSTANCE_CONNECTION_NAME = local.sql_instance_connection_name
})}
EOF

    # 5. Enable and Start the Service
    echo "Reloading systemd and starting service..."
    systemctl daemon-reload
    systemctl enable cloud-sql-proxy.service
    systemctl start cloud-sql-proxy.service

    echo "Startup script finished successfully."
  EOT

# Attach to your VPC
network_interface {
  network    = var.network_name
  subnetwork = var.subnetwork_self_link
}

# Attach the dedicated service account
service_account {
  email  = google_service_account.sql_iap_sa.email
  scopes = ["cloud-platform"]
}

# Allow the project's OS Login settings to apply
metadata = {
  enable-oslogin = "TRUE"
}

# Tag the instance for IAP firewall rules
tags = [var.iap_ssh_tag]
}

resource "google_compute_firewall" "allow_iap" {
  project   = data.google_client_config.this.project
  name      = var.firewall_name
  network   = var.network_name
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports = concat(
      ["22"], # Required for IAP to work
      [var.firewall_allow_database_port],
      var.firewall_additional_ports
    )
  }

  # This is the official, static IP range for Google's IAP service
  source_ranges = var.iap_source_range

  # Applies this rule ONLY to VMs with the specified tag.
  target_tags = [var.iap_ssh_tag]
}

###############
# IAM Resources  
###############

resource "google_service_account" "sql_iap_sa" {
  project      = data.google_client_config.this.project
  account_id   = var.service_account_id
  display_name = var.service_account_display_name
}

resource "google_project_iam_member" "sql_iap_sa_role" {
  project = data.google_client_config.this.project
  role    = var.service_account_role
  member  = google_service_account.sql_iap_sa.member
}
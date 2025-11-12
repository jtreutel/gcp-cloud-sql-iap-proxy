# gcp-cloud-sql-iap-proxy

Creates a small VM to act as an IAP proxy server for Cloud SQL, allowing access to authorized GCP users outside the private network without publicly exposing the database.  The cloud-sql-proxy process on the VM acts as a passthrough for client-side IAM auth, meaning that it preserves the identity of the IAM user in audit logging.

NOTE: This module requires that you [enable IAM auth on your Cloud SQL instance.](https://docs.cloud.google.com/sql/docs/mysql/iam-authentication). Your user MUST have both `roles/cloudsql.client` and `roles/cloudsql.instanceUser` to connect with IAM.


### How to Connect

1. Ensure that your IAM user has the required Cloud SQL permission and has been added to the target DB as an IAM user.  Note your Cloud SQL instance IAM user username, as it will be different than your GCP IAM priniciple name (e.g. `foobar` instead of `foobar@domain.com`)
2. Create an IAP tunnel to the proxy VM by running the command for your target database provided by `output.sql_proxy_tunnel_commands`
3. Run `gcloud auth print-access-token` and copy the token.
4. Log in with the following settings:
  - Host: `localhost`
  - Username: `<your Cloud SQL instance IAM user username>`
  - Password: `<your token>`
  - Port: `<target instance port exposed by cloud-sql-proxy`>
  - Enable cleartext plugin: `true`

## Module Usage Examples

### Minimal Example (Required Variables Only)

This example assumes you are getting your subnetwork information from a data source and connecting to a MySQL instance.

```hcl
data "google_compute_subnetwork" "my_subnetwork" {
  name   = "my-private-subnet"
  region = "us-central1"
}

module "sql_bastion" {
  source = "github.com/jtreutel/gcp-cloud-sql-iap-proxy?ref=vX.Y.Z" #Replace with actual tag

  cloud_sql_instances          = [
    {
      name = "my-mysql-db"
      port = "3306"
    }
  ]
  network_name                 = "my-production-vpc"
  subnetwork_self_link         = data.google_compute_subnetwork.my_subnetwork.self_link
  firewall_allow_database_port = "3306" # MySQL default
}
```

### Full Example (All Variables Overridden)

This example customizes all available options, connecting to a Postgres instance and opening an additional port.

```hcl
data "google_compute_subnetwork" "my_subnetwork" {
  name   = "my-staging-subnet"
  region = "asia-northeast1"
}

module "sql_bastion_custom" {
  source = "github.com/jtreutel/gcp-cloud-sql-iap-proxy?ref=vX.Y.Z" #Replace with actual tag

  # --- Required ---
  cloud_sql_instances          = [
    {
      name = "my-mysql-db"
      port = "33060"
    },
    {
      name = "my-other-mysql-db"
      port = "33061" 
    }
    {
      name = "my-postgres-db"
      port = "5432"
    },
  ]
  network_name                 = "my-staging-vpc"
  subnetwork_self_link         = data.google_compute_subnetwork.my_subnetwork.self_link
  firewall_allow_database_port = "5432" # Postgres default

  # --- Optional ---
  name_prefix                  = "dev-"
  instance_name                = "stg-sql-bastion"
  machine_type                 = "e2-small"
  boot_image                   = "ubuntu-os-cloud/ubuntu-2404-lts"
  cloud_sql_proxy_version      = "v2.20.0"
  iap_ssh_tag                  = "allow-stg-iap"
  firewall_name                = "allow-stg-iap-fw-rule"
  firewall_additional_ports    = ["8080"] # Allow an extra port for a web admin tool
  iap_source_range             = ["35.235.240.0/20"]
  service_account_id           = "stg-sql-bastion-sa"
  service_account_display_name = "Staging SQL Bastion SA"
  service_account_role         = "roles/cloudsql.client"
}
```

-----

## How to Connect

After running `terraform apply`, you can use the commands from the `outputs` to connect.

1.  **To SSH into the bastion:**
    Run the `ssh_command` output.

    ```sh
    gcloud compute ssh --zone <your-zone> <instance-name> --project <your-project>
    ```

2.  **To connect to the database:**
    Run the `sql_proxy_tunnel_command` output in a separate terminal. The port (e.g., `5432`) will match what you provided for `var.firewall_allow_database_port`.

    ```sh
    gcloud compute start-iap-tunnel <instance-name> 5432 --local-host-port=localhost:5432 --zone <your-zone> --project <your-project>
    ```

    This will securely forward the database port on the bastion to your local machine. You can now connect to your database using any client (DBeaver, `psql`, `mysql`, etc.) by pointing it to `localhost:5432`.

-----

## Inputs

### Required

| Name | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `instance_name` | Name of the IAP bastion host VM. | `string` | n/a |
| `sql_instance_name` | The name (ID) of the Cloud SQL instance to connect to. Project and region are detected automatically. | `string` | n/a |
| `network_name` | The name of the VPC network to attach the VM to. | `string` | n/a |
| `subnetwork_self_link` | The self-link of the subnetwork to attach the VM to. | `string` | n/a |
| `firewall_allow_database_port` | Port on which the target Cloud SQL instance is listening. MySQL default is 3306. Postgres default is 5432. SQL Server default is 1433. | `string` | n/a |

### Optional

| Name | Description | Type | Default |
| :--- | :--- | :--- | :--- |
| `machine_type` | Machine type for the IAP bastion host. | `string` | `"e2-micro"` |
| `boot_image` | The boot image for the VM, e.g., 'ubuntu-os-cloud/ubuntu-2204-lts'. | `string` | `"ubuntu-os-cloud/ubuntu-2204-lts"` |
| `cloud_sql_proxy_version` | The version of the Cloud SQL Proxy to install. | `string` | `"v2.19.0"` |
| `iap_ssh_tag` | The network tag used to identify VMs for IAP SSH firewall rules. | `string` | `"allow-iap-ssh"` |
| `firewall_name` | The name of the firewall rule that allows IAP SSH. | `string` | `"allow-iap-ssh-to-tagged-vms"` |
| `firewall_additional_ports` | List of additional ports to allow from the IAP service. | `list(string)` | `[]` |
| `iap_source_range` | The official source IP range for Google's IAP service. | `list(string)` | `["35.235.240.0/20"]` |
| `service_account_id` | The account\_id for the bastion's service account. | `string` | `"sql-iap-bastion-sa"` |
| `service_account_display_name` | The display name for the bastion's service account. | `string` | `"Service Account for SQL IAP Bastion"` |
| `service_account_role` | The IAM role to grant to the service account (e.g., 'roles/cloudsql.client'). | `string` | `"roles/cloudsql.client"` |

-----

## Outputs

| Name | Description |
| :--- | :--- |
| `ssh_command` | Command to SSH into the bastion host using IAP. |
| `sql_proxy_tunnel_command` | Command to start an IAP tunnel to the bastion host for the Cloud SQL Proxy (local port matches `var.firewall_allow_database_port`). |

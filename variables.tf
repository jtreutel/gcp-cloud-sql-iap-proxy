# ------------------------------------------------------------------------------
# REQUIRED VARIABLES
# These variables must be set by the user (e.g., in a terraform.tfvars file).
# ------------------------------------------------------------------------------

variable "instance_name" {
  description = "Name of the IAP bastion host VM."
  type        = string
  default     = "iap-bastion-host"
}

variable "sql_instance_name" {
  description = "The name (ID) of the Cloud SQL instance to connect to. Project and region are detected automatically."
  type        = string
}

variable "network_name" {
  description = "The name of the VPC network to attach the VM to."
  type        = string
}

variable "subnetwork_self_link" {
  description = "The self-link of the subnetwork to attach the VM to."
  type        = string
}

variable "firewall_allow_database_port" {
  description = "Port on which the target Cloud SQL instance is listening. MySQL default is 3306. Postgres default is 5432. SQL Server default is 1433."
  type        = string
}

# ------------------------------------------------------------------------------
# OPTIONAL VARIABLES
# These variables have default values but can be overridden.
# ------------------------------------------------------------------------------

variable "name_prefix" {
  description = "Prefix to add to all resource names."
  type        = string
  default     = ""
}

variable "machine_type" {
  description = "Machine type for the IAP bastion host."
  type        = string
  default     = "e2-micro"
}

variable "boot_image" {
  description = "The boot image for the VM, e.g., 'ubuntu-os-cloud/ubuntu-2204-lts'."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "cloud_sql_proxy_version" {
  description = "The version of the Cloud SQL Proxy to install."
  type        = string
  default     = "v2.19.0"
}

variable "iap_ssh_tag" {
  description = "The network tag used to identify VMs for IAP SSH firewall rules."
  type        = string
  default     = "allow-iap-ssh"
}

variable "firewall_name" {
  description = "The name of the firewall rule that allows IAP SSH."
  type        = string
  default     = "allow-iap-ssh-to-tagged-vms"
}

variable "firewall_additional_ports" {
  description = "List of ports to allow from the IAP service."
  type        = list(string)
  default     = []
}

variable "iap_source_range" {
  description = "The official source IP range for Google's IAP service."
  type        = list(string)
  default     = ["35.235.240.0/20"]
}

variable "service_account_id" {
  description = "The account_id for the bastion's service account."
  type        = string
  default     = "sql-iap-bastion-sa"
}

variable "service_account_display_name" {
  description = "The display name for the bastion's service account."
  type        = string
  default     = "Service Account for SQL IAP Bastion"
}

variable "service_account_role" {
  description = "The IAM role to grant to the service account (e.g., 'roles/cloudsql.client')."
  type        = string
  default     = "roles/cloudsql.client"
}
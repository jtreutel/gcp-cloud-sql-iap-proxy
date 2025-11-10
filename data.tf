# This data source retrieves the project and region configured
# in your gcloud SDK or Terraform provider block.
data "google_client_config" "this" {}
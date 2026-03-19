terraform {
  required_version = ">= 1.6.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.23.0"
    }
  }
}

resource "google_project_service" "required_services" {
  for_each = toset([
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com"
  ])
  project            = var.project_id
  service            = each.key
  disable_on_destroy = false
}

resource "google_kms_key_ring" "state" {
  name     = "state-key-ring"
  location = var.region
  project  = var.project_id
}

resource "google_kms_crypto_key" "state" {
  name            = "state-crypto-key"
  key_ring        = google_kms_key_ring.state.id
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

module "gcs_remote_state_bootstrap" {
  source                          = "git::https://github.com/datasciencecampus/terraform-gcs-remote-state-bootstrap.git?ref=5fd1311f138d9ee1915a57ff4f02d3f80f69f042"
  project_id                      = var.project_id
  storage_object_viewer_principal = var.storage_object_viewer_principal
  storage_object_admin_principal  = var.storage_object_admin_principal
  kms_key_resource_name           = google_kms_crypto_key.state.id
}

output "state_bucket_name" {
  value       = module.gcs_remote_state_bootstrap.state_bucket_name
  description = "The name of the GCS bucket used for Terraform remote state."
}

output "kms_key_resource_name" {
  value       = google_kms_crypto_key.state.id
  description = "The resource name of the KMS crypto key used for state encryption."
}

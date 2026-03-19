variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region"
  default     = "europe-west2"
}

variable "service_name" {
  type        = string
  description = "Cloud Run service name"
  default     = "ons-github-app"
}

variable "artifact_repo" {
  type        = string
  description = "Artifact Registry repository name"
  default     = "ons-github-app"
}

variable "image" {
  type        = string
  description = "Container image URI to deploy"
  default     = ""
}

variable "github_app_id" {
  type        = string
  description = "GitHub App ID"
}

variable "github_accepted_events" {
  type        = string
  description = "Optional comma-separated events allowlist"
  default     = ""
}

variable "services" {
  type        = list(string)
  description = "Additional GCP services to enable"
  default     = ["run.googleapis.com", "artifactregistry.googleapis.com", "iam.googleapis.com", "apigateway.googleapis.com", "secretmanager.googleapis.com"]
}

variable "kms_key_resource_name" {
  description = "The resource name of the KMS crypto key used for state encryption. This should be in the format: projects/{project}/locations/{location}/keyRings/{keyRing}/cryptoKeys/{cryptoKey}"
  type        = string
}

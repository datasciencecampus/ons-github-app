variable "project_id" {
  description = "The GCP project ID."
  type        = string
}

variable "region" {
  description = "GCP region/location for the KMS key ring used to encrypt Terraform state."
  type        = string
  default     = "europe-west2"
}

variable "storage_object_viewer_principal" {
  description = <<EOT
The principal to be granted the Storage Object Viewer role on the state bucket. Must be a valid IAM principal string, e.g.:
  - user:someone@example.com
  - group:admins@example.com
  - serviceAccount:my-sa@project.iam.gserviceaccount.com
  - domain:example.com
EOT
  type        = string
  validation {
    condition     = can(regex("^(user|group|serviceAccount|domain):[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$|^domain:[A-Za-z0-9.-]+$", var.storage_object_viewer_principal))
    error_message = "Principal must be a valid IAM principal string (user, group, serviceAccount, or domain)."
  }
}

variable "storage_object_admin_principal" {
  description = <<EOT
The principal to be granted the Storage Object Admin role on the state bucket. Must be a valid IAM principal string, e.g.:
  - user:someone@example.com
  - group:admins@example.com
  - serviceAccount:my-sa@project.iam.gserviceaccount.com
  - domain:example.com
EOT
  type        = string
  validation {
    condition     = can(regex("^(user|group|serviceAccount|domain):[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$|^domain:[A-Za-z0-9.-]+$", var.storage_object_admin_principal))
    error_message = "Principal must be a valid IAM principal string (user, group, serviceAccount, or domain)."
  }
}

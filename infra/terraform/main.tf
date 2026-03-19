
# --------------------------------------------------------------------------------
# Terraform main configuration for ons-github-app
#
# This file provisions the following GCP resources:
#   - Enables required APIs
#   - Creates a service account for the app
#   - Creates an Artifact Registry Docker repository
#   - Deploys a Cloud Run service (if image is provided)
#   - Configures API Gateway to route webhooks to Cloud Run
#   - Grants API Gateway permission to invoke Cloud Run
#
# Usage:
#   1. Copy terraform.tfvars.example to terraform.tfvars and fill in values.
#   2. Run `terraform init` and `terraform apply`.
#   3. Outputs include service name, service account, registry, and gateway URL.
# --------------------------------------------------------------------------------


terraform {
  required_version = ">= 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.23.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.23.0"
    }
  }
  backend "gcs" {
    bucket = "state__73460913194"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Enables required GCP APIs for Cloud Run, Artifact Registry, IAM, and API Gateway
resource "google_project_service" "services" {
  for_each           = toset(var.services)
  project            = var.project_id
  service            = each.value
  disable_on_destroy = true
}

# Service account for the Cloud Run app
resource "google_service_account" "app" {
  account_id   = "${var.service_name}-sa"
  display_name = "${var.service_name} service account"
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = var.kms_key_resource_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}

# Artifact Registry Docker repository for storing container images
resource "google_artifact_registry_repository" "app" {
  location      = var.region
  repository_id = var.artifact_repo
  format        = "DOCKER"
  kms_key_name  = var.kms_key_resource_name

  depends_on = [google_project_service.services, google_kms_crypto_key_iam_member.crypto_key]
}

# Cloud Run service for the GitHub App (deployed only if image is provided)
resource "google_cloud_run_v2_service" "app" {
  count    = var.image != "" ? 1 : 0
  name     = var.service_name
  location = var.region

  template {
    service_account = google_service_account.app.email

    containers {
      image = var.image

      env {
        name  = "GITHUB_APP_ID"
        value = var.github_app_id
      }

      env {
        name  = "GITHUB_PRIVATE_KEY"
        value = var.github_private_key
      }

      env {
        name  = "GITHUB_WEBHOOK_SECRET"
        value = var.github_webhook_secret
      }

      env {
        name  = "GITHUB_ACCEPTED_EVENTS"
        value = var.github_accepted_events
      }

      ports {
        container_port = 8080
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  depends_on = [google_project_service.services, google_kms_crypto_key_iam_member.crypto_key]
}
data "google_project" "project" {}
# API Gateway setup to route webhook traffic to Cloud Run
resource "google_api_gateway_api" "webhook" {
  provider = google-beta
  api_id   = "webhook-relay"
  project  = var.project_id
}

# API Gateway config using OpenAPI spec (api-config.yaml)
resource "google_api_gateway_api_config" "webhook" {
  provider      = google-beta
  api           = google_api_gateway_api.webhook.api_id
  api_config_id = "webhook-relay-config"
  project       = var.project_id
  openapi_documents {
    document {
      path = "${path.module}/api-config.yaml"
      contents = base64encode(templatefile("${path.module}/api-config.yaml", {
        service_url = google_cloud_run_v2_service.app[0].uri
      }))
    }
  }
  depends_on = [google_api_gateway_api.webhook]
}

# API Gateway instance
resource "google_api_gateway_gateway" "webhook" {
  provider   = google-beta
  gateway_id = "webhook-relay-gateway"
  api_config = google_api_gateway_api_config.webhook.id
  project    = var.project_id
  region     = var.region
}



# Grant API Gateway permission to invoke the Cloud Run service
resource "google_cloud_run_service_iam_member" "gateway_invoker" {
  count      = var.image != "" ? 1 : 0
  service    = google_cloud_run_v2_service.app[count.index].name //
  location   = var.region
  role       = "roles/run.invoker"
  member     = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-apigateway.iam.gserviceaccount.com"
  depends_on = [google_cloud_run_v2_service.app, google_api_gateway_gateway.webhook]
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret
resource "google_secret_manager_secret" "github_private_key" {
  project   = var.project_id
  secret_id = "github-private-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "github_private_key" {
  secret      = google_secret_manager_secret.github_private_key.id
  secret_data = var.github_private_key
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/secret_manager_secret
resource "google_secret_manager_secret" "github_webhook_secret" {
  project   = var.project_id
  secret_id = "github-webhook-secret"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}

resource "google_secret_manager_secret_version" "github_webhook_secret" {
  secret      = google_secret_manager_secret.github_webhook_secret.id
  secret_data = var.github_webhook_secret
}

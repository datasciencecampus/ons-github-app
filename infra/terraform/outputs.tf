output "service_name" {
  description = "Cloud Run service name"
  value       = length(google_cloud_run_v2_service.app) > 0 ? google_cloud_run_v2_service.app[0].name : null
}

output "service_account_email" {
  description = "Service account email"
  value       = google_service_account.app.email
}

output "artifact_registry_repo" {
  description = "Artifact Registry repository name"
  value       = google_artifact_registry_repository.app.repository_id
}

output "gateway_url" {
  description = "API Gateway URL"
  value       = "https://${google_api_gateway_gateway.webhook.default_hostname}/webhooks/github"
}

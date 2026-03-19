
# Terraform Infrastructure for ons-github-app

This folder provisions all required Google Cloud resources for the ons-github-app deployment:

- Enables required GCP APIs (Cloud Run, Artifact Registry, IAM, API Gateway)
- Creates a dedicated service account for the app
- Creates an Artifact Registry Docker repository
- Deploys a Cloud Run service (if an image is provided)
- Configures API Gateway to route GitHub webhook traffic to Cloud Run
- Grants API Gateway permission to invoke the Cloud Run service

## Usage

1. Copy the example tfvars file and fill in your values:

   cp terraform.tfvars.example terraform.tfvars

2. Edit `terraform.tfvars` to set your project, region, and (optionally) the image URI.

3. Initialize and apply the Terraform configuration:

```bash
   terraform init
   terraform apply
```

4. After apply, see the outputs for service name, service account, registry, and API Gateway URL.

## Security & Secrets

- **Do not pass secret values via Terraform variables**. Terraform state is not an appropriate place to store the GitHub private key or webhook secret.
- This module creates Secret Manager *containers*:
   - `github-private-key`
   - `github-webhook-secret`
- Populate secret *versions* outside Terraform (e.g. with `gcloud secrets versions add ...`).
- Cloud Run mounts these secrets as files and the app reads them via:
   - `GITHUB_PRIVATE_KEY_FILE`
   - `GITHUB_WEBHOOK_SECRET_FILE`

## Notes

- Two-phase workflow:
   1) First apply with `image = ""` provisions APIs, service account, Artifact Registry, and Secret Manager secrets.
   2) After pushing an image and adding secret versions, set `image` and apply again to create Cloud Run + API Gateway.

## Outputs

After a successful apply, Terraform will output:

- Cloud Run service name
- Service account email
- Artifact Registry repository name
- API Gateway URL for GitHub webhooks

For more details, see comments in `main.tf` and variable descriptions in `variables.tf`.

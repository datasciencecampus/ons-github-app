
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

2. Edit `terraform.tfvars` to set your project, region, image URI, and GitHub App secrets.

3. Initialize and apply the Terraform configuration:

```bash
   terraform init
   terraform apply
```

4. After apply, see the outputs for service name, service account, registry, and API Gateway URL.

## Security & Secrets

- **Never commit real secrets** (private keys, tokens, passwords) to version control.
- Use `terraform.tfvars.example` as a template only; fill in real values in your local `terraform.tfvars`.
- The Cloud Run service expects secrets via environment variables (see variables in main.tf).
- Example secrets in this repo are placeholders only.

## Notes

- The Cloud Run service expects an image URI in the `image` variable.
- For unauthenticated access, set `allow_unauthenticated = true` (if supported in your configuration).
- API Gateway is configured using `api-config.yaml` and routes traffic to the deployed service.

## Outputs

After a successful apply, Terraform will output:

- Cloud Run service name
- Service account email
- Artifact Registry repository name
- API Gateway URL for GitHub webhooks

For more details, see comments in `main.tf` and variable descriptions in `variables.tf`.

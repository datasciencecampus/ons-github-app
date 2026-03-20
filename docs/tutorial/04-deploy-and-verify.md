# 04 — Provision infra, test locally, deploy, and verify

This tutorial follows the intended flow:

1) Provision shared infra **without** a container image
2) Add secrets to Secret Manager
3) Test locally
4) Build and push the container image
5) Provision the remaining infra (Cloud Run + API Gateway)
6) Update GitHub App webhook URL and verify behavior

## 1) Provision infra (phase 1: no image)

### 1.1 Configure Terraform backend

`infra/terraform/main.tf` uses a GCS backend. Configure the bucket at init time using the `state_bucket_name` you created in tutorial 02.

Edit and run this (replace `<state_bucket_name>`):

```bash
cd infra/terraform
terraform init -backend-config="bucket=<state_bucket_name>"
```

### 1.2 Create `terraform.tfvars`

From `infra/terraform/`:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars`:

- Set `project_id`, `region`, `service_name`, `artifact_repo`
- Set `kms_key_resource_name` from the remote-state output
- Set `github_app_id` from GitHub
- Keep `image = ""` for phase 1

### 1.3 Apply

```bash
cd infra/terraform
terraform apply
```

What you should get after phase 1:

- Artifact Registry repo exists
- Secret Manager secrets exist (containers only):
  - `github-private-key`
  - `github-webhook-secret`
- Cloud Run and API Gateway are **not** created yet (because `image` is blank)

## 2) Add secret values to Secret Manager

This is intentionally **outside Terraform** so secret values do not end up in Terraform state.

This tutorial uses a single approach: secrets are first stored as local files under `./local-secrets/`, then:

- those same files are used for local runs
- and their contents are uploaded to Secret Manager (as secret versions)

Create the local secret files now:

```bash
mkdir -p ./local-secrets/github-private-key ./local-secrets/github-webhook-secret
cp /path/to/private-key.pem ./local-secrets/github-private-key/private_key
printf "%s" "<your-webhook-secret>" > ./local-secrets/github-webhook-secret/webhook_secret
```

### 2.1 Webhook secret

```bash
gcloud secrets versions add github-webhook-secret --data-file=./local-secrets/github-webhook-secret/webhook_secret
```

### 2.2 Private key

```bash
gcloud secrets versions add github-private-key --data-file=./local-secrets/github-private-key/private_key
```

## 3) Test locally (before deploying)

This repo assumes a single local strategy: secrets are stored as files in `./local-secrets/` and the app reads them via `GITHUB_PRIVATE_KEY_FILE` and `GITHUB_WEBHOOK_SECRET_FILE`.

You created `./local-secrets/` in step 2; the commands below read from those files.

### 3.1 Run locally (no Docker)

Create a `.env` (do not commit):

```env
GITHUB_APP_ID=123456
GITHUB_PRIVATE_KEY_FILE=./local-secrets/github-private-key/private_key
GITHUB_WEBHOOK_SECRET_FILE=./local-secrets/github-webhook-secret/webhook_secret
GITHUB_ACCEPTED_EVENTS=pull_request
```

Load it into your shell and run the API:

```bash
set -a
source .env
set +a

uvicorn src.app:app --host 0.0.0.0 --port 8080
```

In another terminal:

```bash
curl http://localhost:8080/healthz
```

### 3.2 Run in Docker (parity with Cloud Run)

This mirrors how Cloud Run runs the container by mounting `./local-secrets` into the container at `/var/secrets`.

```bash
docker build -t ons-github-app:local .

docker run --rm -p 8080:8080 \
  -e GITHUB_APP_ID=123456 \
  -e GITHUB_ACCEPTED_EVENTS=pull_request \
  -e GITHUB_PRIVATE_KEY_FILE=/var/secrets/github-private-key/private_key \
  -e GITHUB_WEBHOOK_SECRET_FILE=/var/secrets/github-webhook-secret/webhook_secret \
  -v "${PWD}/local-secrets:/var/secrets:ro" \
  ons-github-app:local

curl http://localhost:8080/healthz
```

## 4) Build and push the image

### 4.1 Authenticate Docker to Artifact Registry

Edit and run this (replace `<REGION>`):

```bash
gcloud auth configure-docker <REGION>-docker.pkg.dev
```

### 4.2 Build and push (linux/amd64)

Set your variables (edit each line):

```bash
export REGION=<your-region>
```

```bash
export PROJECT_ID=<your-project>
```

```bash
export REPO_NAME=<artifact_repo>
```

```bash
export IMAGE_NAME=<service_name>
```

```bash
export TAG=latest
```

Then build and push:

```bash
docker buildx build --platform linux/amd64 \
  -t ${REGION}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${TAG} \
  --push .
```

## 5) Provision infra (phase 2: deploy)

Update `infra/terraform/terraform.tfvars` with the image you pushed:

```hcl
image = "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO_NAME>/<IMAGE_NAME>:latest"
```

Apply again:

```bash
cd infra/terraform
terraform apply
```

After phase 2:

- Cloud Run service is created
- API Gateway is created and points at Cloud Run
- API Gateway is granted `roles/run.invoker` on the Cloud Run service

## 6) Update GitHub App webhook URL

Get the gateway URL:

```bash
cd infra/terraform
terraform output -raw gateway_url
```

Set your GitHub App webhook URL to that value.

## 7) Verify end-to-end

1) Open a pull request in the repo where the app is installed.
2) In GitHub → your PR, you should see a comment posted by the app.
3) If it doesn’t appear, check:

- Cloud Run logs (look for `event=pull_request action=opened`)
- API Gateway logs
- GitHub App → Advanced → Webhook deliveries

## Why this workflow matters

- Phase 1 lets you review and provision infra safely before you ever deploy code.
- Secrets are added outside Terraform, so you avoid accidental secret leakage into Terraform state.
- Local tests catch webhook/signature/auth bugs before you pay the cloud-debugging tax.

# 01 — Prerequisites and repo overview

## Prerequisites

You need:

- A GCP project with billing enabled.
- `gcloud` installed and authenticated (`gcloud auth login`).
- Terraform >= 1.6.
- Docker (and ideally Buildx for `linux/amd64` builds).
- A GitHub account that can create and install GitHub Apps on the target org/user.

Recommended:

- `pre-commit` installed.
- Permissions in GCP to create Cloud Run, API Gateway, Artifact Registry, Secret Manager secrets, IAM bindings, and KMS keys.

## Repo overview (what code does what)

### Runtime (FastAPI)

- `src/app.py`
  - `POST /webhooks/github` is the GitHub webhook endpoint.
  - Verifies the webhook signature.
  - Handles `pull_request.opened` by posting a comment back on the PR.
  - `GET /healthz` is a health check.

- `src/webhook.py`
  - Computes an HMAC SHA-256 digest of the request body using the webhook secret.
  - Compares it to the `X-Hub-Signature-256` header.

- `src/github_app.py`
  - Creates a GitHub App JWT (signed with the app’s private key).
  - Exchanges it for an **installation access token**.
  - Uses the installation token to call GitHub’s API (post PR comment).

### Secrets strategy (best practice)

- **Local dev**: you can pass secrets via environment variables (e.g. `docker run --env-file .env ...`).
- **Cloud Run**: secrets should not be plain env vars.
  - Store secret values in **Secret Manager**.
  - Mount them into the container as **files**.
  - The app reads them via:
    - `GITHUB_PRIVATE_KEY_FILE`
    - `GITHUB_WEBHOOK_SECRET_FILE`

This keeps secret values out of container images, build logs, and Terraform state.

## Install and run repo tooling (optional but recommended)

From the repo root:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pip install pre-commit
pre-commit install
```

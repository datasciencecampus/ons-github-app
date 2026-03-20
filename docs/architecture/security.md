# Security considerations

This document is a security-focused view of `ons-github-app`.

## Threat model (what we assume)

- The webhook endpoint is internet reachable (via API Gateway).
- Attackers may discover the endpoint URL.
- Attackers may attempt:
  - spoofing webhook events
  - tampering with payloads in transit
  - replaying valid payloads
  - causing excessive request volume (resource/cost pressure)
  - stealing secrets from source control, Terraform state, build logs, or runtime environment

## Primary controls implemented

### Webhook signature verification

- The app verifies `X-Hub-Signature-256` using an HMAC-SHA256 digest of the raw request body.
- Uses constant-time comparison.
- Rejects invalid signatures with HTTP 401.

Outcome:
- Prevents forged payloads that don’t possess the shared webhook secret.

### Short-lived GitHub App auth

- The app signs a JWT (RS256) using the GitHub App private key.
- Exchanges it for an installation access token.
- Uses the installation token to call GitHub’s API.

Outcome:
- Avoids long-lived PATs and bounds token blast radius.

### Secrets kept out of Terraform state and git

- Terraform creates Secret Manager *secret containers* only.
- Secret versions are added with `gcloud secrets versions add ...` outside Terraform.
- Cloud Run mounts secrets as files; the app reads them via `*_FILE` env vars.
- `./local-secrets/` is ignored via `.gitignore`.

Outcome:
- Reduces likelihood of accidental credential leakage.

### Minimal exposed endpoints

- The public API surface is intentionally small:
  - `GET /healthz`
  - `POST /webhooks/github`

## Operational security notes

- Logging: avoid logging secret material or full request bodies. This repo logs the GitHub event type/action only.
- IAM: Cloud Run uses a dedicated service account. That service account is granted Secret Manager access only for the required secrets.

## Known gaps / future hardening ideas

These are not necessarily required for a demo, but are common asks from security review.

- Replay resistance: GitHub webhooks include delivery IDs (e.g. `X-GitHub-Delivery`). Consider storing recent delivery IDs and rejecting duplicates.
- Rate limiting / abuse controls: API Gateway is currently acting as a router. Consider adding quotas/rate limits and alerting on abnormal volume.
- Structured audit logging: capture request metadata (delivery ID, event type, signature verification result) in a structured form.
- Dependency management: requirements are pinned; consider adding dependency update automation and/or vulnerability gates on container images.

## Where to look in code

- Signature verification: `src/webhook.py`
- Secret loading: `src/config.py`
- GitHub App auth + API calls: `src/github_app.py`
- Webhook handler routing: `src/app.py`

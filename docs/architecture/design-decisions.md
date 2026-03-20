# Design decisions

This document captures the key architectural decisions in `ons-github-app` and the rationale behind them.

## Cloud Run for compute

Decision:

- Run the webhook handler as a container on **Google Cloud Run**.

Why:

- Stateless request/response workload suits serverless containers.
- Scales down when idle and scales up when webhook volume increases.
- Avoids VM management and reduces operational overhead.

Trade-offs:

- Cold starts can add latency for the first request after idle.
- Long-running background work is not a good fit; heavy jobs should be offloaded.

## API Gateway in front of Cloud Run

Decision:

- Put **GCP API Gateway** in front of the Cloud Run service.

Why:

- Central place to route and evolve HTTP ingress without exposing Cloud Run URLs directly.
- Keeps the public interface stable while Cloud Run revisions change.

Trade-offs / notes:

- API Gateway is currently configured as a simple reverse proxy using an OpenAPI spec.
- Rate limiting / auth policies are not configured here today; webhook authenticity is enforced at the application layer.

## GitHub webhook authenticity via HMAC signature verification

Decision:

- Treat the request body as untrusted and verify `X-Hub-Signature-256` using HMAC-SHA256.

Why:

- Prevents spoofed/fabricated webhook events from triggering automation.
- Verification occurs before parsing JSON (avoids trusting payload content prematurely).

Trade-offs:

- Does not stop replay by itself (see security doc for mitigations/opportunities).

## GitHub App authentication: JWT + installation tokens

Decision:

- Authenticate to GitHub as a GitHub App:
  - sign a short-lived JWT using the app private key
  - exchange it for an installation access token scoped to the installation

Why:

- Avoids long-lived personal access tokens.
- Installation token scope is bounded to installed repos and expires.

## Secrets strategy: files + Secret Manager

Decision:

- Secrets are not stored in Terraform variables.
- Secret *values* live in **Secret Manager**, mounted as **files** into Cloud Run.
- Locally, secrets are also files under `./local-secrets/`.

Why:

- Keeps secret values out of:
  - git history
  - container images
  - Terraform state
- Using files matches Cloud Run’s secret mount model.

## Two-phase Terraform apply

Decision:

- Use a two-phase workflow:
  1) apply shared infra with `image = ""`
  2) push image + add secret versions + apply again

Why:

- Allows provisioning to succeed before an image exists.
- Ensures secret versions can be added outside Terraform.

## CI security scanning

Decision:

- Run IaC and repo scanning in CI:
  - Checkov (IaC policy scanning)
  - Trivy filesystem scan (dependency and config scanning)

Why:

- Prevents obvious misconfigurations and vulnerable dependencies from landing unreviewed.

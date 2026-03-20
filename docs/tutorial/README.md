# ons-github-app: End-to-end setup tutorial

These docs are the canonical, up-to-date instructions for spinning up the GitHub App in this repo.

## What you’ll build

A GitHub App webhook handler (FastAPI) running on Cloud Run. When a Pull Request is opened, the app posts a simple comment on the PR.

## How the workflow is structured

This repo is designed for a **two-phase Terraform apply**:

1. **Bootstrap & shared infra (no image yet)**
   - Remote state bucket + KMS key
   - Enable APIs
   - Service account
   - Artifact Registry repository
   - Secret Manager *secret containers* (no secret values)

2. **Deploy (once an image exists)**
   - Build/push image
   - Add secret versions to Secret Manager
   - Terraform apply again to create:
     - Cloud Run service
     - API Gateway pointing at Cloud Run

## Tutorials

- 01: Prerequisites and repo overview — see 01-prereqs.md
- 02: Remote state bootstrap — see 02-remote-state.md
- 03: GitHub App setup — see 03-github-app.md
- 04: Deploy & verify (local + cloud) — see 04-deploy-and-verify.md

## Architecture and security

- Architecture overview — see ../architecture/README.md
- Design decisions — see ../architecture/design-decisions.md
- Security considerations — see ../architecture/security.md

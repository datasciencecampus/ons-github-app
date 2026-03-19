#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${SERVICE_NAME:=ons-github-app}"
: "${REGION:=europe-west2}"
: "${GITHUB_APP_ID:?Set GITHUB_APP_ID}"

: "${GITHUB_ACCEPTED_EVENTS:=pull_request}"

IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:latest"

gcloud builds submit --tag "${IMAGE}" .

gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --set-env-vars "GITHUB_APP_ID=${GITHUB_APP_ID},GITHUB_ACCEPTED_EVENTS=${GITHUB_ACCEPTED_EVENTS},GITHUB_PRIVATE_KEY_FILE=/var/secrets/github_private_key,GITHUB_WEBHOOK_SECRET_FILE=/var/secrets/github_webhook_secret" \
  --secret github-app-private-key=/var/secrets/github_private_key \
  --secret github-webhook-secret=/var/secrets/github_webhook_secret

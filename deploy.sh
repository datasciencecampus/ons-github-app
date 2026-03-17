#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${SERVICE_NAME:=ons-github-app}"
: "${REGION:=europe-west2}"

IMAGE="gcr.io/${PROJECT_ID}/${SERVICE_NAME}:latest"

gcloud builds submit --tag "${IMAGE}" .

gcloud run deploy "${SERVICE_NAME}" \
  --image "${IMAGE}" \
  --region "${REGION}" \
  --platform managed \
  --allow-unauthenticated

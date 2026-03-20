#!/usr/bin/env bash
set -euo pipefail

: "${PROJECT_ID:?Set PROJECT_ID}"
: "${REGION:=europe-west2}"
: "${ARTIFACT_REPO:=ons-github-app}"
: "${SERVICE_NAME:=ons-github-app}"
: "${TAG:=latest}"

# This repo's canonical deploy path is Terraform (Cloud Run + API Gateway).
# This script is a convenience to build and push the container image to Artifact Registry.
#
# After running, set the resulting image URI as `image = "..."` in `infra/terraform/terraform.tfvars`
# and run `terraform apply`.

IMAGE="${REGION}-docker.pkg.dev/${PROJECT_ID}/${ARTIFACT_REPO}/${SERVICE_NAME}:${TAG}"

docker buildx build --platform linux/amd64 \
  -t "${IMAGE}" \
  --push .

echo
echo "Pushed image: ${IMAGE}"
echo "Next: update infra/terraform/terraform.tfvars (image = \"${IMAGE}\") and run terraform apply"

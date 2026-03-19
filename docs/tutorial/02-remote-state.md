# 02 — Remote state bootstrap (GCS + KMS)

Terraform state should be stored remotely so it’s durable, shareable, and can be locked.
This repo includes an opinionated bootstrap module under `infra/remote-state/`.

## What this step creates

- Enables:
  - Cloud Storage API
  - Cloud KMS API
  - IAM API
- A KMS key ring + crypto key (used to encrypt Terraform state)
- A GCS bucket for Terraform remote state

## Steps

1) Choose your project and principals

You need:

- `PROJECT_ID` — your GCP project
- A principal to **read** state objects (viewer)
- A principal to **write** state objects (admin)

Examples of principals:

- `user:you@example.com`
- `serviceAccount:ci@your-project.iam.gserviceaccount.com`

2) Create a `terraform.tfvars`

In `infra/remote-state/`, create `terraform.tfvars`:

```hcl
project_id                     = "<your-project-id>"
storage_object_viewer_principal = "user:you@example.com"
storage_object_admin_principal  = "user:you@example.com"
```

3) Apply the bootstrap

```bash
cd infra/remote-state
terraform init
terraform apply
```

4) Capture outputs

Terraform will output:

- `state_bucket_name`
- `kms_key_resource_name`

You’ll use these in the next tutorial.

## Why this matters for your workflow

- Remote state enables safe collaboration and reduces the risk of state loss.
- KMS encryption ensures sensitive metadata in state is encrypted at rest.

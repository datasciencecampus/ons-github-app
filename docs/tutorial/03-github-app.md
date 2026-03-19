# 03 — Create and configure the GitHub App

## What you’re setting up

A GitHub App that:

- Receives `pull_request` webhooks
- Uses an app private key to authenticate as the GitHub App
- Uses an **installation token** to comment on PRs

## Steps (GitHub UI)

1) Create a new GitHub App

- GitHub → Settings → Developer settings → GitHub Apps → **New GitHub App**

2) Basic settings

- **GitHub App name**: choose a unique name
- **Homepage URL**: any valid URL (can be placeholder)

3) Webhook settings

- **Webhook URL**: set a placeholder for now (you will update it after Terraform deploy)
  - Example placeholder: `https://example.com/webhooks/github`
- **Webhook secret**: generate one and save it (you’ll store it in Secret Manager)

Generate a webhook secret locally:

```bash
openssl rand -hex 32
```

4) Permissions (minimum for “comment on PR opened”)

The app posts PR comments via the Issues Comments API (PRs are Issues underneath), so it needs:

- **Repository permissions**
  - Metadata: **Read-only** (required by GitHub)
  - Issues: **Read & write** (to create PR comments)
  - Pull requests: **Read-only** (webhook payload context)

5) Subscribe to events

- Subscribe to: **Pull request** events

6) Create the App and generate a private key

- Create the app
- In the app settings page, generate a private key
- Download the `.pem` file

7) Install the App

- Install the app on your org/user
- Select the repository you want it to operate on

## Values you will need later

- **App ID** (used as `GITHUB_APP_ID`)
- **Webhook secret** (store in Secret Manager)
- **Private key file** (store in Secret Manager)
- **Installation** is included in webhook payloads (the app uses it automatically)

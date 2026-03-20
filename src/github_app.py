import time
from typing import Dict

import jwt
import requests
import logging

from src.config import get_env, normalize_private_key
from src.config import get_secret

GITHUB_API = "https://api.github.com"
logger = logging.getLogger("github-app")
GITHUB_API_VERSION = "2022-11-28"


def create_app_jwt() -> str:
    app_id = get_env("GITHUB_APP_ID")
    private_key_raw = get_secret("GITHUB_PRIVATE_KEY", file_env="GITHUB_PRIVATE_KEY_FILE")
    private_key = normalize_private_key(private_key_raw)
    now = int(time.time())
    payload = {
        "iat": now - 30,
        "exp": now + 540,
        "iss": app_id,
    }
    return jwt.encode(payload, private_key, algorithm="RS256")


def get_installation_token(installation_id: int) -> Dict[str, str]:
    token = create_app_jwt()
    url = f"{GITHUB_API}/app/installations/{installation_id}/access_tokens"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "ons-github-app",
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
    }
    response = requests.post(url, headers=headers, timeout=10)
    if not response.ok:
        logger.error(
            "GitHub installation token request failed status=%s body=%s",
            response.status_code,
            response.text,
        )
    response.raise_for_status()
    data = response.json()
    return {"token": data["token"], "expires_at": data["expires_at"]}


def post_pr_comment(*, installation_id: int, repo_full_name: str, pr_number: int, body: str) -> None:
    """Post a comment to a pull request using the GitHub App installation token."""

    token = get_installation_token(installation_id)["token"]
    url = f"{GITHUB_API}/repos/{repo_full_name}/issues/{pr_number}/comments"
    headers = {
        "Authorization": f"Bearer {token}",
        "Accept": "application/vnd.github+json",
        "User-Agent": "ons-github-app",
        "X-GitHub-Api-Version": GITHUB_API_VERSION,
    }
    response = requests.post(url, headers=headers, json={"body": body}, timeout=10)
    if not response.ok:
        logger.error(
            "GitHub post comment failed repo=%s pr=%s status=%s body=%s",
            repo_full_name,
            pr_number,
            response.status_code,
            response.text,
        )
    response.raise_for_status()

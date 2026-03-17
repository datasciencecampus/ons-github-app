import time
from typing import Dict

import jwt
import requests

from src.config import get_env, normalize_private_key

GITHUB_API = "https://api.github.com"


def create_app_jwt() -> str:
    app_id = get_env("GITHUB_APP_ID")
    private_key = normalize_private_key(get_env("GITHUB_PRIVATE_KEY"))
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
    }
    response = requests.post(url, headers=headers, timeout=10)
    response.raise_for_status()
    data = response.json()
    return {"token": data["token"], "expires_at": data["expires_at"]}

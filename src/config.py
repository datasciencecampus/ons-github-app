import os
from pathlib import Path
from typing import List, Optional


def get_env(name: str, default: Optional[str] = None) -> str:
    value = os.getenv(name, default)
    if value is None:
        raise RuntimeError(f"Missing required env var: {name}")
    return value


def get_secret(name: str, *, file_env: Optional[str] = None, default: Optional[str] = None) -> str:
    """Read a secret either from an env var or from a mounted secret file.

    Best practice on Cloud Run is to mount Secret Manager secrets as files and set
    a non-secret env var that points at the file path (e.g. GITHUB_PRIVATE_KEY_FILE).

    For local development, it's often easiest to provide the secret directly via
    env vars (e.g. via `docker run --env-file .env`).
    """

    file_path = os.getenv(file_env) if file_env else None
    if file_path:
        return Path(file_path).read_text(encoding="utf-8").strip()

    return get_env(name, default)


def normalize_private_key(raw: str) -> str:
    # Allow \n-escaped keys from env vars.
    return raw.replace("\\n", "\n")


def get_accepted_events() -> Optional[List[str]]:
    raw = os.getenv("GITHUB_ACCEPTED_EVENTS")
    if not raw:
        return None
    return [part.strip() for part in raw.split(",") if part.strip()]

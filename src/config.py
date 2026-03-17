import os
from typing import List, Optional


def get_env(name: str, default: Optional[str] = None) -> str:
    value = os.getenv(name, default)
    if value is None:
        raise RuntimeError(f"Missing required env var: {name}")
    return value


def normalize_private_key(raw: str) -> str:
    # Allow \n-escaped keys from env vars.
    return raw.replace("\\n", "\n")


def get_accepted_events() -> Optional[List[str]]:
    raw = os.getenv("GITHUB_ACCEPTED_EVENTS")
    if not raw:
        return None
    return [part.strip() for part in raw.split(",") if part.strip()]

import hmac
import hashlib
from typing import Optional

from src.config import get_env


def verify_signature(body: bytes, signature_header: Optional[str]) -> bool:
    if not signature_header:
        return False

    prefix = "sha256="
    if not signature_header.startswith(prefix):
        return False

    provided = signature_header[len(prefix):]
    secret = get_env("GITHUB_WEBHOOK_SECRET").encode("utf-8")
    digest = hmac.new(secret, body, hashlib.sha256).hexdigest()
    return hmac.compare_digest(provided, digest)

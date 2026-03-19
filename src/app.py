import json
import logging
from typing import Any, Dict

from fastapi import FastAPI, Header, HTTPException, Request

from src.config import get_accepted_events
from src.github_app import get_installation_token, post_pr_comment
from src.webhook import verify_signature

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("github-app")

app = FastAPI()


@app.get("/healthz")
def healthz() -> Dict[str, str]:
    return {"status": "ok"}


@app.post("/webhooks/github")
async def github_webhook(
    request: Request,
    x_github_event: str = Header(default=""),
    x_hub_signature_256: str = Header(default=""),
) -> Dict[str, str]:
    body = await request.body()
    if not verify_signature(body, x_hub_signature_256):
        raise HTTPException(status_code=401, detail="Invalid signature")

    accepted = get_accepted_events()
    if accepted and x_github_event not in accepted:
        return {"status": "ignored"}

    payload = json.loads(body.decode("utf-8"))
    action = payload.get("action")
    logger.info("event=%s action=%s", x_github_event, action)

    if x_github_event == "pull_request" and action == "opened":
        installation_id = payload.get("installation", {}).get("id")
        repo_full_name = payload.get("repository", {}).get("full_name")
        pr_number = payload.get("pull_request", {}).get("number")

        if installation_id and repo_full_name and pr_number:
            try:
                post_pr_comment(
                    installation_id=int(installation_id),
                    repo_full_name=str(repo_full_name),
                    pr_number=int(pr_number),
                    body=(
                        "Thanks for opening this PR — I'm a demo GitHub App running on Cloud Run. "
                        "I'll react to `pull_request.opened` events."
                    ),
                )
            except Exception:
                logger.exception("Failed to post PR comment")
    return {"status": "ok"}


@app.post("/installations/{installation_id}/token")
def installation_token(installation_id: int) -> Dict[str, Any]:
    return get_installation_token(installation_id)

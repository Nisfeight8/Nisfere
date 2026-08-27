import logging

from services.git_service import GitService

logger = logging.getLogger(__name__)

git_svc = GitService()


# ── Outgoing message helpers ──────────────────────────────────────────────────


async def _send_status(repo: str, sock) -> None:
    status = await git_svc.get_status(repo)
    if "error" in status:
        await _send_error(repo, "status", status["error"], sock)
        return
    await sock.send({"type": "git_status", "payload": {"repo": repo, **status}})


async def _send_error(repo: str, action: str, message: str, sock) -> None:
    logger.warning("Git · %s · %s failed: %s", action, repo, message)
    await sock.send(
        {
            "type": "git_error",
            "payload": {
                "repo": repo,
                "action": action,
                "message": message.strip() or f"git {action} failed",
            },
        }
    )


# ── Command handler ───────────────────────────────────────────────────────────


async def handle_command(action: str, payload: dict, sock) -> None:
    repo = payload.get("repo")
    logger.info("Git · %s → %s", action, repo)

    if not repo:
        logger.warning("Git command missing 'repo': %s", payload)
        await _send_error("", action, "Missing 'repo' in payload", sock)
        return

    try:
        match action:
            case "status":
                await _send_status(repo, sock)

            case "stage":
                files = payload.get("files", [])
                success, message = await git_svc.stage(repo, files)
                if not success:
                    await _send_error(repo, action, message, sock)
                    return
                await _send_status(repo, sock)

            case "unstage":
                files = payload.get("files", [])
                success, message = await git_svc.unstage(repo, files)
                if not success:
                    await _send_error(repo, action, message, sock)
                    return
                await _send_status(repo, sock)

            case "commit":
                message_text = payload.get("message", "").strip()
                if not message_text:
                    await _send_error(repo, action, "Commit message is empty", sock)
                    return
                success, err_message = await git_svc.commit(repo, message_text)
                if not success:
                    await _send_error(repo, action, err_message, sock)
                    return
                logger.info("Git · commit succeeded → %s", repo)
                await _send_status(repo, sock)

            case "push" | "pull":
                fn = git_svc.push if action == "push" else git_svc.pull
                success, message = await fn(repo)
                if not success:
                    await _send_error(repo, action, message, sock)
                    return
                logger.info("Git · %s succeeded → %s", action, repo)
                await _send_status(repo, sock)

            case _:
                await _send_error(repo, action, f"Unknown git action: {action}", sock)

    except Exception as e:
        logger.error("Git command error [%s → %s]: %s", action, repo, e)
        await _send_error(repo, action, str(e), sock)

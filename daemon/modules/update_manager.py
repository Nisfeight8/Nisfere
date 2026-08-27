import asyncio
import logging

logger = logging.getLogger(__name__)

_cached_updates: list[dict] = []


async def _run_checkupdates() -> list[dict]:
    try:
        proc = await asyncio.create_subprocess_exec(
            "checkupdates",
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.DEVNULL,
        )
        stdout, _ = await proc.communicate()
        if proc.returncode not in (0, 2):
            return []
        updates = []
        for line in stdout.decode().strip().splitlines():
            parts = line.split()
            if len(parts) >= 4:
                updates.append({"name": parts[0], "current": parts[1], "new": parts[3]})
        return updates
    except FileNotFoundError:
        logger.warning("checkupdates not found — install pacman-contrib")
        return []
    except Exception as e:
        logger.error("check_updates failed: %s", e)
        return []


async def _stream_line(sock, line: str, status: str = "running") -> None:
    await sock.send(
        {"type": "update_stream", "payload": {"line": line, "status": status}}
    )


async def _can_sudo_nopasswd() -> bool:
    try:
        proc = await asyncio.create_subprocess_exec(
            "sudo",
            "-n",
            "pacman",
            "--version",
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        await proc.wait()
        return proc.returncode == 0
    except Exception:
        return False


async def _stream_proc_output(proc, sock) -> None:
    """
    Reads stdout in chunks to handle both \\n and \\r line endings.
    pacman uses \\r for download progress bars — readline() would block
    since \\r doesn't flush the stream. Chunk reading captures everything.
    Deduplicates consecutive identical lines (download progress spam).
    """
    buffer = b""
    last_line = ""

    while True:
        chunk = await proc.stdout.read(512)
        if not chunk:
            break

        buffer += chunk
        # Split on \r and \n — handles both progress bars and regular output
        parts = buffer.replace(b"\r", b"\n").split(b"\n")
        buffer = parts[-1]  # keep incomplete last chunk

        for part in parts[:-1]:
            line = part.decode("utf-8", errors="replace").strip()
            # Skip empty lines and duplicate progress lines
            if line and line != last_line:
                await _stream_line(sock, line)
                last_line = line

    # Flush remaining buffer
    if buffer:
        line = buffer.decode("utf-8", errors="replace").strip()
        if line and line != last_line:
            await _stream_line(sock, line)


async def _run_stream_updates(sock) -> None:
    """
    Streams pacman -Syu output live via socket.

    Auth strategy:
      1. sudo -n NOPASSWD  → no dialog, full streaming
         Setup: echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman"
                | sudo tee /etc/sudoers.d/nisfere-pacman
      2. pkexec            → polkit GUI dialog
         Requires polkit agent in hyprland.conf:
         exec-once = /usr/lib/polkit-kde-authentication-agent-1
    """
    global _cached_updates

    await _stream_line(sock, "Checking authentication...", "start")

    if await _can_sudo_nopasswd():
        await _stream_line(sock, "Using sudo (NOPASSWD)", "running")
        # No --noprogressbar: we want the output so we can stream it.
        # Chunk reading handles the \r-based progress lines.
        cmd = ["sudo", "-n", "pacman", "-Syu", "--noconfirm"]
    else:
        await _stream_line(sock, "Requesting polkit authorization...", "running")
        cmd = ["pkexec", "pacman", "-Syu", "--noconfirm"]

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )

        await _stream_proc_output(proc, sock)
        await proc.wait()

        if proc.returncode == 0:
            _cached_updates = []
            await _stream_line(sock, "System is up to date ✓", "done")
        elif proc.returncode == 127:
            await _stream_line(
                sock,
                'Authorization failed. Run: echo "$USER ALL=(ALL) NOPASSWD: /usr/bin/pacman"'
                " | sudo tee /etc/sudoers.d/nisfere-pacman",
                "error",
            )
        else:
            await _stream_line(sock, f"Update failed (exit {proc.returncode})", "error")

    except asyncio.CancelledError:
        proc.terminate()
        await _stream_line(sock, "Update cancelled", "error")
    except Exception as e:
        logger.error("stream_updates error: %s", e)
        await _stream_line(sock, f"Error: {e}", "error")


async def handle_command(action: str, payload: dict, sock) -> None:
    global _cached_updates

    match action:
        case "check_updates":

            async def _do_check():
                global _cached_updates
                _cached_updates = await _run_checkupdates()
                logger.info("Arch updates: %d available", len(_cached_updates))
                await sock.send(
                    {
                        "type": "arch_updates",
                        "payload": {
                            "updates": _cached_updates,
                            "count": len(_cached_updates),
                        },
                    }
                )

            asyncio.create_task(_do_check())

        case "get_cached_updates":
            await sock.send(
                {
                    "type": "arch_updates",
                    "payload": {
                        "updates": _cached_updates,
                        "count": len(_cached_updates),
                        "cached": True,
                    },
                }
            )

        case "run_updates":

            async def _do_update():
                global _cached_updates
                await _run_stream_updates(sock)
                _cached_updates = await _run_checkupdates()
                await sock.send(
                    {
                        "type": "arch_updates",
                        "payload": {
                            "updates": _cached_updates,
                            "count": len(_cached_updates),
                        },
                    }
                )

            asyncio.create_task(_do_update())

        case _:
            logger.warning("Unknown update action: '%s'", action)

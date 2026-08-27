import asyncio
import json
import logging
import signal

from services.socket_manager import DevShellSocket
from modules import (
    docker_manager,
    theme_controller,
    sys_monitor,
    update_manager,
    process_manager,
    git_manager,
)

# ── Logging setup ────────────────────────────────────────────────────────────

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    datefmt="%H:%M:%S",
)
logger = logging.getLogger(__name__)

# ── Config ───────────────────────────────────────────────────────────────────

STATS_INTERVAL: float = 2.0

COMMAND_ROUTER = {
    "docker": docker_manager.handle_command,
    "theme": theme_controller.handle_command,
    "updates": update_manager.handle_command,
    "processes": process_manager.handle_command,
    "git": git_manager.handle_command,
}

# ── Core logic ────────────────────────────────────────────────────────────────


async def stats_loop(sock: DevShellSocket) -> None:
    while True:
        if sock.has_active_connections():
            try:
                stats = await sys_monitor.get_system_stats()
                await sock.send(stats)
            except Exception as e:
                logger.error("Stats loop error: %s", e)
        await asyncio.sleep(STATS_INTERVAL)


async def handle_command(msg: str, sock: DevShellSocket) -> None:
    try:
        data = json.loads(msg)
    except json.JSONDecodeError as e:
        logger.warning("Invalid JSON received: %s", e)
        return

    module_name: str | None = data.get("module")
    action: str | None = data.get("action")
    payload: dict = data.get("payload", {})

    if not module_name:
        logger.warning("Command missing 'module' key: %s", data)
        return

    handler = COMMAND_ROUTER.get(module_name)
    if handler is None:
        logger.warning("Unknown module: '%s'", module_name)
        return

    try:
        await handler(action, payload, sock)
    except Exception as e:
        logger.error("Error in %s.%s: %s", module_name, action, e)


# ── Entry point ───────────────────────────────────────────────────────────────


async def main() -> None:
    sock = DevShellSocket()
    server = await sock.start_server(lambda msg: handle_command(msg, sock))

    loop = asyncio.get_running_loop()
    shutdown = asyncio.Event()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, shutdown.set)

    logger.info("Nisfere Daemon started")

    async with server:
        done, pending = await asyncio.wait(
            [
                asyncio.create_task(stats_loop(sock)),
                asyncio.create_task(server.serve_forever()),
                asyncio.create_task(shutdown.wait()),
            ],
            return_when=asyncio.FIRST_COMPLETED,
        )
        for task in pending:
            task.cancel()

    logger.info("Daemon stopped.")


if __name__ == "__main__":
    asyncio.run(main())

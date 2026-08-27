import asyncio
import json
import logging

from services.docker_service import DockerService

logger = logging.getLogger(__name__)

docker_svc = DockerService()


# ── Stream manager ────────────────────────────────────────────────────────────


class _StreamManager:
    """Tracks active streaming tasks and their subprocesses as pairs."""

    def __init__(self):
        self._streams: list[tuple[asyncio.Task, asyncio.subprocess.Process]] = []

    def register(self, task: asyncio.Task, proc) -> None:
        self._streams.append((task, proc))

    def stop_all(self) -> None:
        for task, proc in self._streams:
            task.cancel()
            try:
                proc.terminate()
            except Exception:
                pass
        self._streams.clear()
        logger.debug("All streams stopped")


_streams = _StreamManager()


# ── Stream coroutines ─────────────────────────────────────────────────────────


async def _stream_stats(proc, sock) -> None:
    try:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            raw = line.decode("utf-8").strip()
            start = raw.find("{")
            end = raw.rfind("}") + 1
            if start == -1 or end == 0:
                continue
            try:
                await sock.send(
                    {"type": "stream_stat", "payload": json.loads(raw[start:end])}
                )
            except json.JSONDecodeError:
                pass
    except asyncio.CancelledError:
        pass
    finally:
        proc.terminate()


async def _stream_logs(proc, sock) -> None:
    try:
        while True:
            line = await proc.stdout.readline()
            if not line:
                break
            await sock.send({"type": "stream_log", "payload": line.decode("utf-8")})
    except asyncio.CancelledError:
        pass
    finally:
        proc.terminate()


# ── Command handler ───────────────────────────────────────────────────────────


async def handle_command(action: str, payload: dict, sock) -> None:
    target = payload.get("target")
    action_type = payload.get("action_type", "container")
    logger.info("Docker · %s · %s → %s", action_type, action, target)

    try:
        match action:
            case "get_stats":
                stats = await asyncio.to_thread(docker_svc.get_docker_status)
                await sock.send(stats)

            case "inspect_container":
                details = await asyncio.to_thread(
                    docker_svc.get_container_details, target
                )
                await sock.send(details)

            case "start_stream":
                _streams.stop_all()
                stats_proc = await docker_svc.get_stats_process(target)
                logs_proc = await docker_svc.get_logs_process(target)
                _streams.register(
                    asyncio.create_task(_stream_stats(stats_proc, sock)), stats_proc
                )
                _streams.register(
                    asyncio.create_task(_stream_logs(logs_proc, sock)), logs_proc
                )

            case "stop_stream":
                _streams.stop_all()

            case _:
                # Container / image / volume / compose actions
                if action_type == "compose":
                    success = await docker_svc.docker_action_async(
                        action, target, action_type
                    )
                else:
                    success = await asyncio.to_thread(
                        docker_svc.docker_action, action, target, action_type
                    )

                # Explicit, correlated "this specific action just finished"
                # message — sent BEFORE the generic stats refresh below, and
                # deliberately separate from it. The client can't reliably
                # infer "my action is done" from the next docker_stats that
                # happens to arrive, because the client also polls get_stats
                # on its own independent timer — an unrelated periodic poll
                # response could arrive WHILE this action is still running
                # and would look identical to a real completion. Carrying
                # action_type/action/target here lets the client match this
                # response to the specific action that triggered it, with
                # no ambiguity, regardless of what else is in flight.
                #
                # For compose, `target` is the whole project object the
                # client sent (working_dir, config_files, a snapshot of its
                # containers, ...) — only working_dir is a stable
                # correlation key, so that's all we echo back here rather
                # than the full (and potentially large/stale) object.
                result_target = target
                if action_type == "compose" and isinstance(target, dict):
                    result_target = {"working_dir": target.get("working_dir", "")}

                await sock.send(
                    {
                        "type": "action_result",
                        "payload": {
                            "action_type": action_type,
                            "action": action,
                            "target": result_target,
                            "success": success,
                        },
                    }
                )

                if success:
                    await sock.send(
                        await asyncio.to_thread(docker_svc.get_docker_status)
                    )
                else:
                    await sock.send(
                        {
                            "type": "error",
                            "payload": {
                                "action": action,
                                "error": "Docker action failed",
                            },
                        }
                    )

    except Exception as e:
        logger.error("Docker command error [%s]: %s", action, e)
        exc_target = target
        if action_type == "compose" and isinstance(target, dict):
            exc_target = {"working_dir": target.get("working_dir", "")}
        await sock.send(
            {
                "type": "action_result",
                "payload": {
                    "action_type": action_type,
                    "action": action,
                    "target": exc_target,
                    "success": False,
                },
            }
        )
        await sock.send(
            {
                "type": "error",
                "payload": {"action": action, "error": str(e)},
            }
        )
